/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: Son Ngoc Nguyen
* Tags: 
*/


model Productsonshelf

/* Insert your model definition here */
/*
 * Description:
 * - Agent: People
 * Init with a fix number, having friendship graph, having opinion about the shop
 * 		Action: an amount of people comes to shop with expect product
 * 		
 */



global {
	file product_data_file <- csv_file("includes/product.csv", ",", string, true);
	shape_file open_area_shape_file <- shape_file("results/open area.shp");
	shape_file wall_shapefile <- shape_file("results/walls.shp");
	shape_file pedestrian_paths_shape_file <- shape_file("results/pedestrian paths.shp");
	shape_file shelves_shapefile <- shape_file("results/shelves.shp");
	shape_file free_spaces_shape_file <- shape_file("results/free spaces.shp");
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
	int nb_people <- 10;
	int nb_product <- 10;
	geometry open_area ;
	geometry free_space <- envelope(free_spaces_shape_file);
	
	//social graph (not spatial) representing the friendship links between people
	graph friendship_graph <- graph([]);
	graph product_graph <- graph([]);
	
	file counter_shapefile <- file("results/counter.shp");
	file doorIn_shapefile <- file("results/doorin.shp");
	file doorOut_shapefile <- file("results/doorout.shp");
	file floor_shapefile <- file("results/floor.shp");
	
	
	geometry shape_counter <- envelope(counter_shapefile);
	geometry shape_doorIn <- envelope(doorIn_shapefile);
	geometry shape_doorOut <- envelope(doorOut_shapefile);
	geometry shape_floor <- envelope(floor_shapefile);
	geometry shape_wall <- envelope(wall_shapefile);
	
	//Time definition
	float step <- 1 #second; 
 	int daily <- 600 ; //cycles / day
 	int numberOfDays <- 0; 
 	int shopperCounts;
 	
 	float first_customers_rate <- 0.1 ; // 10% of population
	
//	float patienceTime_global <- 100 #cycle;// 5.0 #minute ; 
	string prod_at_location <- "prod_at_location";
	string reject_prod_location <- "reject_prod_location";
	
	predicate travel_to_shop <- new_predicate("want to shopping ");
	
	predicate shopping <- new_predicate(" have target product "); 
	predicate saw_product <- new_predicate(prod_at_location);
	predicate choose_product <- new_predicate("choose a product"); 
//	predicate reject_prod_location <- new_predicate("rejected product");
	
	predicate found_product <- new_predicate("found one target product");
	predicate found_all_product <- new_predicate("found all target product");
	
	predicate loose_patience <- new_predicate("loose patience"); 
	predicate loose_patience_pay <- new_predicate("found some target product"); 
	predicate loose_patience_empty <- new_predicate("cannot found target product");
	
	predicate need_pay <- new_predicate ("picked some products");
	predicate need_leave <- new_predicate ("leave");
	predicate spread_rumors <- new_predicate ("recommend to friends");
	
	// product order strategy weight
	float product_price_weight <- rnd(0.0,1.0) min: 0.0 max: 1.0;
	float nb_product_weight <- rnd(0.0, 1.0) min: 0.0 max: 1.0;
	float product_link_weight <- rnd(0.0, 1.0) min: 0.0 max: 1.0;
	float bias_weight <- rnd(0.0, 1.0) min: 0.0 max: 1.0;
	
	init {
		create counter from:counter_shapefile;
		create doorIn from:doorIn_shapefile;
		create doorOut from:doorOut_shapefile;
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
//			location <- any_location_in(one_of(open_area));
			location <- any_location_in(one_of(doorIn));
//			write "patienceTime default " + patienceTime ;
//			patienceTime <- myself.patienceTime_global; 
			
//			write "patienceTime " + myself.patienceTime + " " + patienceTime ;
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
	
	// TODO: more specific pause condition
	reflex stop when: every(daily#cycle){ // empty(people) or (shopperCounts =0)  {
		
		if (numberOfDays+1 >1){
		ask people{
//			write "Try re init";
			do re_init;
		} 
		}
		do pause;
		
		
		
	}
	
	// program clock
	reflex current_time when: every(daily#cycle) {
//		write "Now is " + time/6; 
		// Re-calculate shopping need here
		numberOfDays <- numberOfDays + abs((cycle - numberOfDays*daily)/daily);
		write "Day: " + (numberOfDays+1);
		// TODO: recalculate states
	}
	
}

species pedestrian_path skills: [pedestrian_road]{
	aspect default { 
		draw shape  color: #gray;
	}
	aspect free_area_aspect {
		if(display_free_space and free_space != nil) {
			draw free_space color: #lightpink border: #black;
		}
		
	}
}

species shelves {
	aspect default {
		draw shape color:#pink;
	}
}

species wall {
	
	geometry free_space;
	float high <- rnd(10.0, 20.0);
	
	aspect demo {
		draw shape border: #black depth: high texture: ["../includes/top.png","../includes/texture5.jpg"];
	}
	
	aspect default {
		draw shape + (P_shoulder_length/2.0) color: #gray border: #black;
	}
}

species people skills: [pedestrian, moving] parallel: true control:simple_bdi{
	rgb color <- rnd_color(255);
	float speed <- gauss(2,1) #km/#h min: 1 #km/#h;
	point target ;
	point movePath;
	point friend_map <- any_location_in(world);
	
	float patienceTime <-  30#minute ;
	bool keepPatience <- false;
	float walkinTime;
	float searching_time<- 0;
	float counting_time;
	float payment_time <- 0;
	
	bool need_product <- false;
	list<product_type> productList <- rnd(1, length(product_type)) among product_type;

	list<point> checkProd;
	list<string> boughtList <- [];
	list<string> foundList <- [];
	int found_number <-0;
	
//	string current_status;
	float view_dist<-5.0; //dist seeing the product
	float pick_dist<-1.0; //dist to pick the product
	
	list<people> friends;
	float converge <- rnd(0.0,1.0);
	float rumor_threshold <-0.2;	
	float opinion <- 0 max:1.0;
	
	float happiness <-0 max:1.0;
	
	float comeback_rate_threshold <-0.6 min: 0.6; // as first opinion is 0.8
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
//		do add_desire(travel_to_shop);
		target <- nil;
		happiness <-0;
		ask self {
			location <- any_location_in(one_of(doorIn));
		}
		
	}
	
//	reflex update {
//		do status;
//		switch current_status{
//			match need_product {
//				do add_desire(shopping);
//			}
//		}
//	}
	
//	action status {
//		
//	}
	
	
	/**
	 * executed at each iteration to update the agent's Belief base, 
	 * to know the changes in its environment (the world, the other 
	 * agents and itself). The agent can perceive other agents up 
	 * to a fixed distance or inside a specific geometry.
	 */
	perceive target: product_type where(!(each.location in checkProd)) in: view_dist parallel: true {
//	write "self.name " + self.name;
//	write "myself.productList " + myself.productList;
	if (self.name in myself.productList){
	
		focus id: prod_at_location var: location; // belief to saw_product
		write "prod_at_location " + location;
		ask myself {
	        do remove_intention(shopping, false);
	        
	    }	
	    }
	}
	
	/**
	 * executed at each iteration to infer new desires or beliefs 
	 * from the agent's current beliefs and desires,
	 */
	rule belief: saw_product new_desire: found_product strength: 4;
	rule belief: found_product new_desire: shopping strength: 5;
	rule belief: found_all_product new_desire: need_pay strength: 3;
//	rule belief: loose_patience_pay new_desire: need_pay strength: 6;
//	rule belief: loose_patience_empty new_desire: need_leave strength: 1;
	
	reflex comeback when: every(daily#cycle){
//		write "run comeback " +opinion;

		comeback_rate <- (int(need_product) + opinion + happiness)/3;
//		write "comeback_rate " + comeback_rate;
		if  (comeback_rate >= comeback_rate_threshold) {
			need_product <- true;
			productList <- rnd(1, length(product_type)) among product_type;
			shopperCounts <- shopperCounts +1;
			
			do add_desire(shopping);
			walkinTime <- time;
			keepPatience <- true;
			write"walkinTime " + walkinTime;
		}
		

	}
	// The current intention will determine the selected planThe current intention will determine the selected plan
	plan lets_wander intention:shopping finished_when: has_desire(found_all_product) or has_desire(loose_patience){
		movePath <- any_location_in(open_area);
		do moveAround;
	} 
	
	// choose the product in sight
	plan choose_best_product intention: choose_product instantaneous: true{
		list<point> possible_product <- get_beliefs_with_name(prod_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		list<point> reject_prod <- get_beliefs_with_name(reject_prod_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		possible_product <- possible_product - reject_prod;
		if (empty(possible_product)) {
//			write "empty product";
			do remove_intention(found_product, true); 
//			write "choose_best_product remove_intention(found_product) ";
		} else {
			target <- (possible_product with_min_of (each distance_to self)).location;
			write "update target " + target;
		}
		do remove_intention(choose_product, true); 
	}
	
	plan get_product intention:found_product {
		//find all products in list
		// if found all change do add_belief(found_product);
//		write "get_product ";
		if (target = nil) {
			do add_subintention(get_current_intention(),choose_product, true);
			do current_intention_on_hold();
//			write "current_intention_on_hold ";
		} else {
//			write "goto target: target " + target;
			do goto target: target ;
			if (target distance_to location) <=1  {
				product_type current_product<- product_type first_with (target = each.location);
				
				if (current_product != nil and flip(current_product.height_chance)) {
					
				 	write "get_gold add_belief(has_gold) ";
//					ask current_product {quantity <- quantity - 1;}	

					// TODO Hiep Option: add product to list
					productList <- [];
					foundList <- ["pen"];
					boughtList <- ["pen"];
					
					// if all product is getted from this then we update belief
					if (length(productList)=0 and length(foundList)>0){
						do add_belief(found_all_product);
						do remove_belief(found_product);
						do remove_belief(shopping);
						write "Found all prod";
					}else{do add_belief(found_product);}

				}
//				else{
					do add_belief(new_predicate(reject_prod_location, ["location_value"::target]));
					add target to: checkProd;
					write "move on " +target;
//				}

				target <- nil;
			}
		}	
	}
	
	
	
	plan leave intention: need_leave {
		// if run out of patience time do add_belief(loose_patience);
			// out of patience and bought some products do add_belief(need_pay);
			// out of patience and bought do add_belief(need_leave);
		do remove_belief(found_product);
		do remove_belief(found_all_product);
		do remove_belief (shopping);
	
		target <- any_location_in(one_of(doorOut));
		write "door OUT";
		do goto target: target ;
		shopperCounts <- shopperCounts -1;
//		if (target = location)  {
//			target <- any_location_in(one_of(doorIn));
//			do goto target: target ; // back to the population
//			write "back to population";
//			shopperCounts <- shopperCounts -1;
//		}
	}
	
	plan pay intention: need_pay {
//		write" pay " + target;
		
		do remove_belief(found_product);
		do remove_belief(found_all_product);
		do remove_belief (shopping);
			
		target <- any_location_in(one_of(counter));
		write"pay target " + target ;
		do goto target: target ;
//		movePath <-any_location_in(one_of(counter));
		do moveAround;
		if (location  distance_to target)<=1  {
			counting_time <- cycle;
			
			write "return_to_base remove_belief(found_product) ";
//			do remove_intention(need_pay, true);
			
			//TODO Hiep Optional: add value price to sale number
			//TODO: stand and waiting for payment speed
			// payment_time = 
			write "paid";
		}
		payment_time <- counting_time +length(boughtList)*10; //cycle
		if cycle >= payment_time {
			do add_desire(need_leave);
			do remove_intention(need_pay, true); 
		}
		
		
	}
	
	plan keepPatience intention: loose_patience {
		// if run out of patience time do add_belief(loose_patience);
			// out of patience and bought some products do add_belief(need_pay);
			// out of patience and bought do add_belief(need_leave);
		do remove_belief(shopping);
		do remove_belief(found_product);
		do remove_belief(found_all_product);
		write "loose_patience";
		if length(boughtList) >0{
			do add_desire(need_pay);
			write "need_pay";
//			do remove_belief(loose_patience);
			do remove_intention(loose_patience, true);
		}
		else{
			write "need_leave";
			do add_desire (need_leave);
			do remove_intention(loose_patience, true);
		}
	}
	
	plan recommend intention: spread_rumors instantaneous: true {
	//		list<people> my_friends <- list<people>((social_link_base where (each.liking > 0)) collect each.agent);
		ask friends {
			if (abs(myself.opinion - opinion) < rumor_threshold) { //only influence if there is a opinion difference
				float temp <- opinion;
				// influencing formulae
				opinion <- opinion + converge * (myself.opinion - opinion);
				myself.opinion <- myself.opinion + converge * abs(myself.opinion - temp);
				do add_intention(travel_to_shop); // action of recommendation travel_to_shop will calculate need to shopping
			}
		}
		do remove_intention(spread_rumors, true);
	}
	
	action moveAround {
		if (walkinTime != nil and time > walkinTime + patienceTime) {
			if (final_waypoint = nil) {
				do compute_virtual_path pedestrian_graph: network target: any_location_in(one_of(doorOut));
			}

			do walk;
		} else {
			if (final_waypoint = nil) {
				do compute_virtual_path pedestrian_graph: network target: any_location_in(open_area);
			}

			do walk;
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


species product_type parallel: true {	
	int id;
	string name;	
	string price_type;
	int price;
	int linked_id; // deprecated
	list<product_type> my_links;
	
	// Eye-level > top-level > lower-level
	float height_chance <- 0.9; //default a random chance of buying
	
	// Height must in list [ "high", "eye", "low" ]
	string height;
	
	// Product arrangement strategy parameter
	float prod_price_percent;
	float nb_product_percent;
	float product_link_percent;
	float flip_percent <- 0.0;
	
	// basic params	
	action update_order_param_part_1 {
		prod_price_percent <- price / sum(product_type collect each.price);
		nb_product_percent <- length(product_type where(each.name = self.name)) / length(product_type);
	}
	
	// advance params
	action update_order_param_part_2 { // should be call after all products are created
		product_link_percent <- (prod_price_percent + sum(my_links collect each.prod_price_percent)) / (length(my_links) + 1);	
		flip_percent <- flip_percent + product_price_weight * prod_price_percent;
		flip_percent <- flip_percent + nb_product_weight * nb_product_percent;
		flip_percent <- flip_percent + product_link_weight * product_link_percent;
		flip_percent <- flip_percent + bias_weight;
		flip_percent <- flip_percent / 4;	
	}
	
	action update_height {
		write flip_percent;
		if(flip(flip_percent)) {
			height <- "eye";
		} else if (flip(flip_percent)) {
			height <- "high";
		} else {
			height <- "low";
		}
	}
	
	aspect default {
		draw circle(1) color: #black;
	}
}


species product_link parallel: true{
	
	aspect default {
		draw shape color: #orange;
	}
}


species counter {
	aspect default {
		draw shape color: rgb (128, 64, 3) border: #red;
	}
}

species floors {
	
//	float capacity;
	aspect default {
		draw shape color:#pink;
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
		display map type: opengl{
//			species floors aspect: default;
			species wall refresh: false;
			species shelves aspect: default;
			
			species counter aspect: default;
			species doorIn aspect: default;
			species doorOut aspect: default;
			
			species pedestrian_path aspect:free_area_aspect transparency: 0.5 ;
			species pedestrian_path refresh: false;
			species people;	
			species product_type;
		}
		display friendship type: opengl{
			species friendship_link ;
			species people aspect: friends_default;
			}
		display product_type type: opengl{
			species product_link ;
			species product_type;
			}
		display reputation_graph refresh: every(daily#cycle) { //refresh reputation graph daily
			
			chart "Reputation in Population" type: series  {
			loop ag over: people  {
				data ag.name value: ag.opinion color: #blue;
		}
		}
			}
	}
}
 
