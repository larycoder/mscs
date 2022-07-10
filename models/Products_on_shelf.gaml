/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: group 2
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
	shape_file free_spaces_shape_file <- shape_file("results/free spaces.shp");
	file shelves_shapefile <- file("results/shelves.shp");
	file wall_shapefile <- file("results/walls.shp");
	
	
	
	shape_file open_area_shape_file <- shape_file("results/open area.shp");
	shape_file pedestrian_paths_shape_file <- shape_file("results/pedestrian paths.shp");

	
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
	int nb_people <- 50;
	int nb_product <- 15;
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
 	float first_customers_rate <- 0.1 ; // 10% of population
	
	float patienceTime <- 20*15 #second;
	
	string prod_at_location <- "prod_at_location";
	string reject_prod_location <- "reject_prod_location";
	
	predicate shopping <- new_predicate(" have target product ");
	predicate saw_product <- new_predicate(prod_at_location);
	predicate choose_product <- new_predicate("choose a product"); 
//	predicate reject_prod_location <- new_predicate("rejected product");
	
	predicate found_product <- new_predicate("found all target product");
	predicate loose_patience <- new_predicate("cannot found target product");
	predicate need_pay <- new_predicate ("picked some products");
	predicate need_leave <- new_predicate ("leave");
	predicate spread_rumors <- new_predicate ("recommend to friends");
	
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
		
		create people number:nb_people {
//			location <- any_location_in(one_of(open_area));
			location <- any_location_in(one_of(doorIn));
//			write "patienceTime default " + patienceTime ;
			patienceTime <- myself.patienceTime; 
			walkinTime <- time;
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
		

		int need_shopping <- int(abs(first_customers_rate*nb_people));
		loop times: need_shopping {
			
			one_of(people).needShopping <- true;
		}
		
		loop times: nb_people*2 {

			people p1 <- one_of(people);
			people p2 <- one_of(list(people) - p1);
			
			create friendship_link  {
				add edge (p1, p2, self) to: friendship_graph;
				shape <- link(p1,p2);
			}
		}
		
		
		create product_type number:nb_product{
			
		}
		loop times: nb_product/2 {
			product_type pr1 <- one_of(product_type);
			product_type pr2 <- one_of(list(product_type) - pr1);
			
			create product_link  {
				add edge (pr1, pr2, self) to: product_graph;
				shape <- link(pr1,pr2);
			}
		}
			
	}
	
	reflex stop when: empty(people) {
		do pause;
	}
	
	
	reflex current_time {
		write "Now is " + time/6; 
		// Re-calculate shopping need here
		
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

species people skills: [pedestrian] parallel: true control:simple_bdi{
	rgb color <- rnd_color(255);
	float speed <- gauss(1,0.1) #km/#h min: 0.1 #km/#h;
	point target ;
	
	float patienceTime <- 30.0 #minute ; 
	float walkinTime;
	bool needShopping <- false;
	list<string> productList <- ["toothpaste", "noodle"];
//	list<string> my_names <- my_agents collect each.name;


	list<string> boughtList <- [];
	list<string> foundList <- [];
	int found_number <-0;
	
	string current_status;
	float view_dist<-3.0; //dist seeing the product
	float pick_dist<-1.0; //dist to pick the product
	
	
	init{
		if (needShopping) {
			do add_desire(shopping);
		}
		
	}
	
	
	reflex update {
		do status;
		switch current_status{
			match needShopping {
				do add_desire(shopping);
			}
		}
	}
	
	action status {
		
	}
	
//	predicate shopping <- new_predicate(" have target product ");
//	predicate found_product <- new_predicate("found all target product");
//	predicate loose_patience <- new_predicate("cannot found target product");
//	predicate need_pay <- new_predicate ("picked some products");
//	predicate need_leave <- new_predicate ("leave");
//	predicate spread_rumors <- new_predicate ("recommend to friends");
	
	/**
	 * executed at each iteration to update the agent's Belief base, 
	 * to know the changes in its environment (the world, the other 
	 * agents and itself). The agent can perceive other agents up 
	 * to a fixed distance or inside a specific geometry.
	 */
	perceive target: shelves  in:view_dist {
//		ask myself {
//		//collect the product
//		//update score
//		May not need this 
//		}
	focus id: prod_at_location var: location; // belief to saw_product
	ask myself {
        do remove_intention(shopping, false);
        
    }	
		
	}
	
	/**
	 * executed at each iteration to infer new desires or beliefs 
	 * from the agent's current beliefs and desires,
	 */
	rule belief: saw_product new_desire: found_product strength: 2.0;
	rule belief: found_product new_desire: need_pay strength: 3.0;
//	rule belief: need_leave new_desire: found_product strength: 2.0;
	
	
	// The current intention will determine the selected planThe current intention will determine the selected plan
	plan lets_wander intention:shopping finished_when: has_desire(found_product) or has_desire (loose_patience){
		do moveAround;
	} 
	
	// choose the product in sight
	plan choose_best_product intention: choose_product instantaneous: true{
		list<point> possible_product <- get_beliefs_with_name(prod_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		list<point> reject_prod <- get_beliefs_with_name(reject_prod_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		possible_product <- possible_product - reject_prod;
		if (empty(possible_product)) {
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
		} else {
			do goto target: target ;
			if (target = location)  {
				product_type current_product<- product_type first_with (target = each.location);
				
				if (flip(current_product.height_chance)) {
					do add_belief(found_product);
				 	write "get_gold add_belief(has_gold) ";
//					ask current_product {quantity <- quantity - 1;}	

					// TODO: add product to list
				}
				else{
					do add_belief(new_predicate(reject_prod_location, ["location_value"::target]));
					write "get_product new_predicate(reject_prod_location) ";
				}
				
				
//				if current_product.height_chance > 0 {
					
//				} 
//				else {
//					do add_belief(new_predicate(empty_mine_location, ["location_value"::target]));
//					write "get_gold add_belief(empty_mine_location) ";
//				}
				target <- nil;
			}
		}	
		
		
		if (length(productList)=0 and length(foundList)>0){
			do add_belief(found_product);
		}
		
		  
	}
	
	
	
	plan leave intention: need_leave {
		// if run out of patience time do add_belief(loose_patience);
			// out of patience and bought some products do add_belief(need_pay);
			// out of patience and bought do add_belief(need_leave);
	}
	
	plan pay intention: need_pay {
		// if run out of patience time do add_belief(loose_patience);
			// out of patience and bought some products do add_belief(need_pay);
			// out of patience and bought do add_belief(need_leave);
		do remove_intention(need_pay, true); 
		do remove_intention(found_product, true);
	}
	
	plan keepPatience intention: loose_patience {
		// if run out of patience time do add_belief(loose_patience);
		if (time > walkinTime +patienceTime){
			do add_belief(loose_patience);
			do remove_intention(found_product, true);
			
		}
		
			// out of patience and bought some products do add_belief(need_pay);
			// out of patience and bought do add_belief(need_leave);
	}
	
//	reflex move when: needShopping {
	action moveAround {
		
		if (walkinTime !=nil and time > walkinTime +patienceTime){
			if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph:network target: any_location_in(one_of(doorOut)) ;
		}
			do walk ;
		
		}else{
			if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph:network target: any_location_in(open_area) ;
		}
			do walk ;
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
	int category;
	
	int price;
	string PrType;
	
	// Eye-level > top-level > lower-level
	float height_chance <- 0.5; //default a random chance of buying
	
	
//	location <- any_location_in (on_of(shelves)); // and in a grid overlay, avoid location where we already has other product
//	int height one_of(["high", "eye", "low"]);
	
	aspect default {
		draw shape color: #yellow;
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
			
			
			
			
		}
		display friendship type: opengl{
			species friendship_link ;
			species people;
			
			}
		display product_type type: opengl{
			species product_link ;
			species product_type;
			
			}
	}
}
 