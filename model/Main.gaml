/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Main

import "People.gaml"

/* Insert your model definition here */
/*
 * Description:
 * - Agent: People
 * Init with a fix number, having friendship graph, having opinion about the shop
 * 		Action: an amount of people comes to shop with expect product
 * 		
 */



global {
	file product_data_file <- csv_file("../includes/product.csv", ",", string, true);
	shape_file open_area_shape_file <- shape_file("../results/open area.shp");
	shape_file wall_shapefile <- shape_file("../results/walls.shp");
	shape_file pedestrian_paths_shape_file <- shape_file("../results/pedestrian paths.shp");
	shape_file shelves_shapefile <- shape_file("../results/shelves.shp");
	shape_file free_spaces_shape_file <- shape_file("../results/free spaces.shp");
	graph network;
	geometry shape <- envelope(wall_shapefile);

	bool display_free_space <- false parameter: true;
	bool display_force <- false parameter: true;
	bool display_target <- false parameter: true;
	bool display_circle_min_dist <- true parameter: true;
	
	float P_shoulder_length <- 0.45 parameter: true;
	float P_proba_detour <- 0.5 parameter: true ;
	bool P_avoid_other <- true parameter: true ;
	float P_obstacle_consideration_distance <- 3.0 parameter: true ;
	float P_pedestrian_consideration_distance <- 3.0 parameter: true ;
	float P_tolerance_target <- 0.1 parameter: true;
	bool P_use_geometry_target <- true parameter: true;
	
	
	string P_model_type <- "simple" among: ["simple", "advanced"] parameter: true ; 
	
	float P_A_pedestrian_SFM_advanced parameter: true <- 0.16 category: "SFM advanced" ;
	float P_A_obstacles_SFM_advanced parameter: true <- 1.9 category: "SFM advanced" ;
	float P_B_pedestrian_SFM_advanced parameter: true <- 0.1 category: "SFM advanced" ;
	float P_B_obstacles_SFM_advanced parameter: true <- 1.0 category: "SFM advanced" ;
	float P_relaxion_SFM_advanced  parameter: true <- 0.5 category: "SFM advanced" ;
	float P_gama_SFM_advanced parameter: true <- 0.35 category: "SFM advanced" ;
	float P_lambda_SFM_advanced <- 0.1 parameter: true category: "SFM advanced" ;
	float P_minimal_distance_advanced <- 0.25 parameter: true category: "SFM advanced" ;
	
	float P_n_prime_SFM_simple parameter: true <- 3.0 category: "SFM simple" ;
	float P_n_SFM_simple parameter: true <- 2.0 category: "SFM simple" ;
	float P_lambda_SFM_simple <- 2.0 parameter: true category: "SFM simple" ;
	float P_gama_SFM_simple parameter: true <- 0.35 category: "SFM simple" ;
	float P_relaxion_SFM_simple parameter: true <- 0.54 category: "SFM simple" ;
	float P_A_pedestrian_SFM_simple parameter: true <-4.5category: "SFM simple" ;
	
//	float step <- 0.1;
	int nb_people <- 20;
	int nb_product <- 15;
	geometry open_area ;
	geometry free_space <- envelope(free_spaces_shape_file);
	
	//social graph (not spatial) representing the friendship links between people
	graph friendship_graph <- graph([]);
	graph product_graph <- graph([]);
	
	file counter_shapefile <- file("../results/counter.shp");
	file doorIn_shapefile <- file("../results/doorin.shp");
	file doorOut_shapefile <- file("../results/doorout.shp");
	file floor_shapefile <- file("../results/floor.shp");
	
	
	geometry shape_counter <- envelope(counter_shapefile);
	geometry shape_doorIn <- envelope(doorIn_shapefile);
	geometry shape_doorOut <- envelope(doorOut_shapefile);
	geometry shape_floor <- envelope(floor_shapefile);
	geometry shape_wall <- envelope(wall_shapefile);
	
	//Time definition
	float step <- 1 #second; 
 	int daily <- 1200 ; //cycles / day
 	int numberOfDays <- 0; 
 	int shopperCounts;
 	
 	float first_customers_rate <- 0.25 ; // 10% of population
	
	float patienceTime_global <- daily #cycle;// 5.0 #minute ; 
	string prod_at_location <- "prod_at_location";
	string reject_prod_location <- "reject_prod_location";
	
	predicate travel_to_shop <- new_predicate("want to shopping ");
	
	predicate shopping <- new_predicate(" have target product "); 
	predicate saw_product <- new_predicate(prod_at_location);
	predicate choose_product <- new_predicate("choose a product"); 
//	predicate reject_prod_location <- new_predicate("rejected product");
	
	predicate found_product <- new_predicate("found one target product");
	predicate found_all_product <- new_predicate("found all target product");
	
	predicate loose_patience <- new_predicate("cannot found target product");
	predicate need_pay <- new_predicate ("picked some products");
	predicate need_leave <- new_predicate ("leave");
	predicate spread_rumors <- new_predicate ("recommend to friends");
	
	// product order strategy weight
	float product_price_weight <- rnd(0.0,1.0) min: 0.0 max: 1.0;
	float nb_product_weight <- rnd(0.0, 1.0) min: 0.0 max: 1.0;
	float product_link_weight <- rnd(0.0, 1.0) min: 0.0 max: 1.0;
	float bias_weight <- rnd(0.0, 1.0) min: 0.0 max: 1.0;
	
	// monitor shop
	int total_shopping_people <- 0;
	int total_buying_people <- 0;
	int total_revenue <- 0;
	float avg_happiness <- 0.0 update: mean(people collect(each.happiness));
	
	init {
		create counter from:counter_shapefile;
		create doorIn from:doorIn_shapefile;
		create doorOut from:doorOut_shapefile;
		create product_owner number: 1;
		create floors from:open_area_shape_file {
			shape <- open_area;
		}
		create wall from:wall_shapefile;
		
		open_area <- first(open_area_shape_file.contents);
		create shelves from:shelves_shapefile;
		
		create pedestrian_path from: pedestrian_paths_shape_file {
			list<geometry> fs <- free_spaces_shape_file overlapping self;
			free_space <- fs first_with (each covers shape); 
			
		}

		network <- as_edge_graph(pedestrian_path);
		ask pedestrian_path parallel: true{
			do build_intersection_areas pedestrian_graph: network;
		}
		
		create product_type from: product_data_file {
			location <- any_location_in(one_of(shelves));

			// recompute location to avoid overlapping
			loop while: not empty((product_type - self) at_distance 3) {
				location <- any_location_in(one_of(shelves));
			}
		}

		// create product link
		loop times: nb_product/2 {
			product_type pr1 <- one_of(product_type);
			product_type pr2 <- one_of(list(product_type) - pr1);
			
			create product_link  {
				add edge (pr1, pr2, self) to: product_graph;
				shape <- link(pr1,pr2);
				ask pr1 { if not (my_links contains pr2) {my_links << pr2;} }
				ask pr2 { if not (my_links contains pr1) {my_links << pr1;} }
			}
		}
		
		// compute flip percentage for product arrangement strategy
		ask product_type { do update_order_param_part_1; }
		ask product_type { do update_order_param_part_2; }

		// normalize flip percentage
		list<float> flip_percent_list <- product_type collect each.flip_percent;
		float min_flip <- min(flip_percent_list);
		float max_flip <- max(flip_percent_list);
		float range_flip <- max_flip - min_flip;
		
		// update height of product
		ask product_type {
			flip_percent <- (flip_percent - min_flip) / range_flip;
			do update_height;
		}
		
		create people number:nb_people {

			location <- any_location_in(one_of(doorIn));

			patienceTime <- myself.patienceTime_global; 

			obstacle_consideration_distance <-P_obstacle_consideration_distance;
			pedestrian_consideration_distance <-P_pedestrian_consideration_distance;
			shoulder_length <- P_shoulder_length;
			avoid_other <- P_avoid_other;
			proba_detour <- P_proba_detour;
			
			use_geometry_waypoint <- P_use_geometry_target;
			tolerance_waypoint<- P_tolerance_target;
			pedestrian_species <- [people];
			obstacle_species<-[ wall];
			
			pedestrian_model <- P_model_type;
			if (pedestrian_model = "simple") {
				A_pedestrians_SFM <- P_A_pedestrian_SFM_simple;
				relaxion_SFM <- P_relaxion_SFM_simple;
				gama_SFM <- P_gama_SFM_simple;
				lambda_SFM <- P_lambda_SFM_simple;
				n_prime_SFM <- P_n_prime_SFM_simple;
				n_SFM <- P_n_SFM_simple;
			} else {
				A_pedestrians_SFM <- P_A_pedestrian_SFM_advanced;
				A_obstacles_SFM <- P_A_obstacles_SFM_advanced;
				B_pedestrians_SFM <- P_B_pedestrian_SFM_advanced;
				B_obstacles_SFM <- P_B_obstacles_SFM_advanced;
				relaxion_SFM <- P_relaxion_SFM_advanced;
				gama_SFM <- P_gama_SFM_advanced;
				lambda_SFM <- P_lambda_SFM_advanced;
				minimal_distance <- P_minimal_distance_advanced;
			
			}
		}
		loop ag over: people{
			create people_mind number:nb_people{
			self.person <- ag;
		}
		}
		
		// Init random need shopping people with first_customers_rate
		int need_shopping <- int(abs(first_customers_rate*nb_people));
		loop times: need_shopping {
			people p1 <- one_of(people where(each.need_product != true));
			
			p1.need_product <- true;
			p1.opinion <- 0.8; // init first opinion
			
		}
		
		// Create random friendship graph
		loop times: abs(nb_people*1.5) {

			people p1 <- one_of(people);
			people p2 <- one_of(list(people) - p1);
			
			create friendship_link  {
				add edge (p1, p2, self) to: friendship_graph;
				shape <- link(p1.friend_map,p2.friend_map);
			}
		}
	}	
	
	action quit_game(bool ready){
		if (not ready){
			do die;
		}
	} 

	int round <- 0;
	bool end_of_round <- true;
	reflex set_end_of_round when: every(daily){
		end_of_round <- true;
	}

	reflex update_round when: end_of_round{

		if(round < 10){
			ask counter {
				round_shopping_people <- 0;
				round_buying_people <- 0;
			}
			if (round > 0){
				
				
				loop ag over: people_mind {
					
					ag.friends <- ag.person.friends;
					ag.happiness <- ag.person.happiness;
					ag.comeback_rate <- ag.person.comeback_rate;
					ag.comeback_rate_threshold <- ag.person.comeback_rate_threshold;
					ag.opinion <- ag.person.opinion;
					ask ag.person{
						do die;
					}
					create ag.person  {
						location <- any_location_in(one_of(doorIn));
			friends <- ag.friends;
			happiness <- ag.happiness;
			comeback_rate <- ag.comeback_rate;
			comeback_rate_threshold <- ag.comeback_rate_threshold;
			opinion <- ag.opinion;
			
			patienceTime <- myself.patienceTime_global; 

			obstacle_consideration_distance <-P_obstacle_consideration_distance;
			pedestrian_consideration_distance <-P_pedestrian_consideration_distance;
			shoulder_length <- P_shoulder_length;
			avoid_other <- P_avoid_other;
			proba_detour <- P_proba_detour;
			
			use_geometry_waypoint <- P_use_geometry_target;
			tolerance_waypoint<- P_tolerance_target;
			pedestrian_species <- [people];
			obstacle_species<-[ wall];
			
			pedestrian_model <- P_model_type;
			if (pedestrian_model = "simple") {
				A_pedestrians_SFM <- P_A_pedestrian_SFM_simple;
				relaxion_SFM <- P_relaxion_SFM_simple;
				gama_SFM <- P_gama_SFM_simple;
				lambda_SFM <- P_lambda_SFM_simple;
				n_prime_SFM <- P_n_prime_SFM_simple;
				n_SFM <- P_n_SFM_simple;
			} else {
				A_pedestrians_SFM <- P_A_pedestrian_SFM_advanced;
				A_obstacles_SFM <- P_A_obstacles_SFM_advanced;
				B_pedestrians_SFM <- P_B_pedestrian_SFM_advanced;
				B_obstacles_SFM <- P_B_obstacles_SFM_advanced;
				relaxion_SFM <- P_relaxion_SFM_advanced;
				gama_SFM <- P_gama_SFM_advanced;
				lambda_SFM <- P_lambda_SFM_advanced;
				minimal_distance <- P_minimal_distance_advanced;
				
				}
					}
				
				
			}
				
//				ask people {
//				//			write "Try re init";
//					do re_init;
//				}
			}
			round <- round + 1;
			
			ask product_owner {
				do arrange_product_by_player;
			}

			end_of_round <- false;
		}
		else {
			do pause;
		}
	}
}

species shelves {
	aspect default {
		draw shape color:#pink;
	}
}
species people_mind {
	list<people> friends;
	float happiness <-0 min: 0.0 max:1.0;
	float comeback_rate;
	float comeback_rate_threshold <-0.2 min: 0.1; 
	float opinion <- 0 max:1.0;
	people person;
}
species people skills: [pedestrian, moving] parallel: true control:simple_bdi{
	rgb color <- rnd_color(255);
	float speed <- gauss(1,0.1) #km/#h min: 0.1 #km/#h;
	point target ;
	point friend_map <- any_location_in(world);
	string movement <- "wander";
	bool shopper <- false;
	bool is_bought <- false;
	
	float patienceTime <-  30#minute ;
	float walkinTime;
	float searching_time<- 0;
	float counting_time;
	float payment_time <- 0;
	
	bool need_product <- false;
	list<product_type> productList <- rnd(1, length(product_type)) among product_type;
	
	list<string> checkList;
	list<point> checkProd;
	list<string> boughtList <- [];
	list<string> foundList <- [];
	int found_number <-0;
	float foundTime ;
//	string current_status;
	float view_dist<-5.0; //dist seeing the product
	float pick_dist<-1.0; //dist to pick the product
	
	list<people> friends;
	float converge <- rnd(0.0,1.0);
	float rumor_threshold <-0.2;	
	float opinion <- 0 max:1.0;
	
	float happiness <-0 min: 0.0 max:1.0;
	
	float comeback_rate_threshold <-0.2 min: 0.1; // as first opinion is 0.8
	// probability of go shopping
	float comeback_rate <- (float(need_product) + opinion + happiness)/3 max:1.0;
	
	init{
		friends <- list<people>(friendship_graph neighbors_of (self));
	}
	
	action re_init {
		write "re-init people";
		walkinTime <- nil;
		searching_time<- 0;
		payment_time <- 0;
		comeback_rate_threshold <- 0.7; // assume that first happiness > 0.5
		target <- nil;
	}
	

	/**
	 * executed at each iteration to update the agent's Belief base, 
	 * to know the changes in its environment (the world, the other 
	 * agents and itself). The agent can perceive other agents up 
	 * to a fixed distance or inside a specific geometry.
	 */
	perceive target: product_type where(!(each.location in checkProd)) in: view_dist  parallel: true {
	myself.checkList <- myself.productList collect(each.name);
	if (self.name in myself.checkList){
	
		focus id: prod_at_location var: location; // belief to saw_product
		write "prod_at_location " + location;
		ask myself {
	        do remove_intention(shopping, false);
	    }	}}
	
	/**
	 * executed at each iteration to infer new desires or beliefs 
	 * from the agent's current beliefs and desires,
	 */
	rule belief: saw_product new_desire: found_product strength: 2.0;
	rule belief: found_product new_desire: shopping strength: 3.0;
	rule belief: found_all_product new_desire: need_pay strength: 4.0;
	rule belief: need_leave new_desire: need_leave strength: 6.0;

	
	reflex comeback when: every(daily#cycle){

		comeback_rate <- (int(need_product) + opinion + happiness)/3;

		if  (comeback_rate >= comeback_rate_threshold) {
			need_product <- true;
			productList <- rnd(1, 1) among product_type;
			shopperCounts <- shopperCounts +1;
			write "productList " + productList;
			ask counter {
				round_shopping_people <- round_shopping_people + 1;
				total_shopping_people <- total_shopping_people + 1;
			}
			
			do add_desire(shopping);
			shopper <- true;
			walkinTime <- time;
		}
	}
	
	// The current intention will determine the selected planThe current intention will determine the selected plan
	plan lets_wander intention:shopping finished_when: has_desire(found_all_product) or 
	has_desire (loose_patience) or has_desire(need_pay) or has_desire(need_leave){
		do moveAround;
	} 
	
	// choose the product in sight
	plan choose_best_product intention: choose_product instantaneous: true{
		list<point> possible_product <- get_beliefs_with_name(prod_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		list<point> reject_prod <- get_beliefs_with_name(reject_prod_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		
		possible_product <- possible_product - reject_prod;
		
		if (empty(possible_product) or (length(productList)=0 and length(foundList)>0)) {
			write "empty product";
			do remove_intention(found_product, true); 
			write "choose_best_product remove_intention(found_product) ";
		} else {
			target <- (possible_product with_min_of (each distance_to self)).location;
		}
		do remove_intention(choose_product, true); 
	}
	
	plan get_product intention:found_product {
		//find all products in list
		// if found all change do add_belief(found_product);
		
		if (target = nil) {
			do add_subintention(get_current_intention(),choose_product, true);
			do current_intention_on_hold();
		} 
		else {
			do goto target: target ;
			if (target distance_to location) <=1  {
				product_type current_product<- product_type first_with (target = each.location);
				
				if (current_product != nil and flip(current_product.height_chance) and length(productList)>0) {
					
				 	write "get_gold add_belief(has_gold) ";
//					ask current_product {quantity <- quantity - 1;}	
					// if all product is getted from this then we update belief
					foundList << current_product.name;
					boughtList << current_product.name;
					productList <- productList where(each != current_product);
					write "boughtList " + boughtList;
					if (length(productList)=0 and length(foundList)>0){
						
						do add_belief(found_all_product);
						foundTime <- time;
						do remove_belief(found_product);
						do remove_belief(shopping);
						do remove_intention(found_product, true);
						do remove_intention(shopping, true);
						write "update when found all product";
					}else{do add_belief(found_product);}	
				}
				else{
					do add_belief(new_predicate(reject_prod_location, ["location_value"::target]));
					write "get_product new_predicate(reject_prod_location) ";
				}

				target <- nil;
			}}	}
	

	plan leave intention: need_leave {
//		movement <- "counter";
//		do moveAround;

//		write "run to door out";
//		if (final_waypoint = nil) {
//		do compute_virtual_path pedestrian_graph:network target: any_location_in(one_of(doorOut)) ;
//		}
//		do walk ;
		
		if self in agents_overlapping(doorOut)  {
			if (is_bought) {
				ask counter {
					round_buying_people <- round_buying_people + 1;
					total_buying_people <- total_buying_people + 1;
				}
			}	

			write "done shopping";
			do remove_intention(need_leave, false);

			
		}
		else{
//			target <- any_location_in(one_of(doorOut));
//			write "door OUT";
//			do goto target: target ;
			
//			write "door OUT";
			movement <- "doorOut";
			do moveAround;
		}

		
		 
	}
	
	plan pay intention: need_pay {
		// if run out of patience time do add_belief(loose_patience);
			// out of patience and bought some products do add_belief(need_pay);
			// out of patience and bought do add_belief(need_leave);
		
//		write "need pay";
		if (shopper){
//			target <- any_location_in(one_of(counter));
//			do goto target: target ;
			
			movement <- "counter";
			do moveAround;
		}
		
		
//		movement <- "counter";
//		do moveAround;

//		write "run to counter";
//		if (final_waypoint = nil) {
//		do compute_virtual_path pedestrian_graph:network target: any_location_in(one_of(counter)) ;
//		}
//		do walk ;
			
		if  self in agents_overlapping(counter) {// (target distance_to location)<=1  {
			if counting_time =0 or counting_time =nil {
				counting_time <- cycle;
			}
			
			do remove_belief(found_product);
			do remove_belief(found_all_product);
//			write "paying ";
//			do remove_intention(need_pay, true);
			if not empty(boughtList) {
				is_bought <- true;
			}
			ask counter {
				loop prod over: myself.boughtList {
					write "one_of(product_type where(each.name = prod)).price; " + one_of(product_type where(each.name = prod)).price;
					total_revenue <- total_revenue + one_of(product_type where(each.name = prod)).price;
				}
			}
		
		payment_time <- int(counting_time +length(boughtList)*10); //cycle
//		write "payment_time " + payment_time; 
//		write "counting_time " + counting_time; 
//		write " cycle " + cycle;
		if cycle >= payment_time {
			do add_desire(need_leave);
			shopper <- false ; 
//			write "done paid";
			do remove_intention(need_pay, true); 
		}
		}
	}
	
	reflex search_time {
		searching_time <- walkinTime +patienceTime;
		if (time > searching_time){
//			write "loose patience";
//			do add_desire(loose_patience);
		}
	}
		
	plan keepPatience intention: loose_patience {
		// if run out of patience time do add_belief(loose_patience);
			// out of patience and bought some products do add_belief(need_pay);
			// out of patience and bought do add_belief(need_leave);
		if length(boughtList) >0{
			do add_desire(need_pay);
			do remove_belief(shopping);
			do remove_belief(loose_patience);
			do remove_intention(loose_patience, true);
		}
		else{
			write "loose patience";
			do add_desire (need_leave);
			do remove_intention(loose_patience, true);
		}
	}
	
	plan recommend intention: spread_rumors instantaneous: true{
//		list<people> my_friends <- list<people>((social_link_base where (each.liking > 0)) collect each.agent);
		write "spread_rumors";
		
		do spreadRumors;

		do remove_intention(spread_rumors, true); 
	}
	
	
	reflex everyday_calculation when: every(daily#cycle) and cycle >10 {
		write "everyday_calculation ";
		// happiness
		float searchingTime <-  (foundTime - walkinTime)/patienceTime;
		float paymentTime <- payment_time/patienceTime;
		
		float bought_per_shoppingList ;
		if (length(boughtList) = 0){
			bought_per_shoppingList <- 0;
		}else{bought_per_shoppingList <- (1.0 - length(productList)/length(boughtList));}
		
		happiness <- bought_per_shoppingList - paymentTime - searchingTime;
		
		do spreadRumors;
		
		//TODO Update sale numbers
	} 
	action spreadRumors {
		ask friends{
			if(abs(myself.opinion-opinion) < rumor_threshold ){ //only influence if there is a opinion difference
				float temp <- happiness;
			// influencing formulae
			opinion <- opinion + converge*(myself.happiness-opinion);
			myself.opinion <- myself.opinion + converge*abs(myself.opinion-temp);
			}
		}
	}
	
	
	

	action moveAround {
		

		if (movement = "doorOut"){
//			write "run to door out";
			if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph:network target: any_location_in(one_of(doorOut)) ;
		}
			do walk ;
		
		}
		if (movement = "counter") {
//			write "run to counter";
			if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph:network target: any_location_in(one_of(counter)) ;
		}
			do walk ;
		}
		if (movement = "wander"){
			if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph:network target: any_location_in(open_area) ;
		}
			do walk ;
		}
		
	}	
	
	aspect friends_default {
		
		/**
		 * Green: friends who go shopping
		 *	Red: friends who doesnt
		 */
		if need_product{ 
			draw circle( 0.5, friend_map )  color: #green; 
		}else{
			draw circle( 0.5, friend_map )  color: #red;
		}
		
	}
	aspect default {
		
		if display_circle_min_dist and minimal_distance > 0 {
			draw circle(minimal_distance).contour color: color;
		}
		
		draw circle(view_dist) color: color border: #black wireframe: true;
		
		draw triangle(shoulder_length) color: color rotate: heading + 90.0;
		
		if display_target and current_waypoint != nil {
			draw line([location,current_waypoint]) color: color;
		}
		if  display_force {
			loop op over: forces.keys {
				if (species(agent(op)) = wall ) {
					draw line([location, location + point(forces[op])]) color: #red end_arrow: 0.1;
				}
				else if ((agent(op)) = self ) {
					draw line([location, location + point(forces[op])]) color: #blue end_arrow: 0.1;
				} 
				else {
					draw line([location, location + point(forces[op])]) color: #green end_arrow: 0.1;
				}
			}
		}	
	}
}


species friendship_link parallel: true{
	
	aspect default {
		draw shape color: #blue;
	}
}


species socialLinkRepresentation{
	people origin;
//	agent destination;
	float recommendation;
	rgb my_color;
	
	aspect base{
		draw line([origin,recommendation],50.0) color: my_color;
	}
}


species doorIn {
	aspect default {
		draw shape border:#black color:#green;
	}
}

species doorOut {
	aspect default {
		draw shape color: #navy border: #black;
	}
}


experiment normal_sim type: gui {
	float minimum_cycle_duration <- 0.02;
	output {
		display map type: opengl {
		//			species floors aspect: default;
			species wall refresh: false;
			species shelves aspect: default;
			species counter aspect: default;
			species doorIn aspect: default;
			species doorOut aspect: default;
//			species pedestrian_path aspect: free_area_aspect transparency: 0.5;
			species pedestrian_path refresh: false;
			species people;
			species product_type;
		}

//		display friendship type: opengl {
//			species friendship_link;
//			species people aspect: friends_default;
//		}
//
//		display product_type type: opengl {
//			species product_link;
//			species product_type;
//		}
//
		display reputation_graph refresh: every(daily #cycle) { //refresh reputation graph daily
			chart "Reputation in Population" type: series {
				loop ag over: people_mind {
					data ag.name value: ag.opinion color: #blue;
				}
			}
		}
	}

}

experiment test type:gui{
	output{
		display main_stage refresh: end_of_round{
			
			graphics "Stats"{
				draw "Round: "+round+"/10" at: {10,10} color: #green;
				//draw "High-level: "+ string(selector at "High-level") at: {20,20} color: #red;
				//draw "Eye-level: "+ string(selector at "Eye-level") at: {20,25} color: #red;
				//draw "Low-level: "+ string(selector at "Low-level") at: {20,30} color: #red;
				
//				draw "Current round status" at: {0,140} color: #red;
//				draw "Came client: "+ tround_shopping_people at: {20,160} color: #red;
//				draw "Served client: "+ round_buying_people at: {20,170} color: #red;
//				draw "Revenue: "+ round_revenue at: {20,180} color: #red;
				
			}
		}
		display "Total status"{
			chart "Total status" type:histogram 
									x_label:''
			 						y_label:'' {
					data "Total came client" value: total_shopping_people color:#blue;
					data "Total served client" value: total_buying_people color:#yellow;
					data "Total revenue" value: total_revenue/1000 color:#grey;
				}
		}
		display "Round status" refresh:every(daily){
			chart "Past information" type:series
									x_label:''
			 						y_label:'' {
					data "Total came client" value: one_of(counter).round_shopping_people  color:#blue;
					data "Total served client" value: one_of(counter).round_buying_people color:#yellow; 
					data "Total revenue" value: one_of(counter).round_revenue/1000 color:#grey;
				}
		}
		display "Happiness"{
			chart "Avarage happiness" type:series{
				data "Avg. Happiness" value: avg_happiness color:#darkgrey;
			}
		}
	}
}
 