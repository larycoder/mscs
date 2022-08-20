/**
* Name: People
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model People

import "People.gaml"

/* Insert your model definition here */

import "../Main.gaml"

global{
	///////////PEDESTRIAN/////////////////
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
	
	
}

species people skills: [pedestrian, moving] parallel: true{
	
	
	
	
	
	
	
	
	
	
	rgb color <- rnd_color(255);
	float speed <- gauss(1,0.1) #km/#h min: 0.1 #km/#h;
	point target ;
	point friend_map <- any_location_in(world);
	string movement <- "wander";
	string status <- "idle";
	bool shopper <- false;
	
	float patienceTime <-  30#minute ;
	float walkinTime;
	float searching_time<- 0;
	float counting_time;
	float payment_time <- 0;
	
	bool need_product <- false;
	list<string> productList <- ["pen"];


	list<point> checkProd;
	list<string> boughtList <- [];
	list<string> foundList <- [];
	int found_number <-0;
	float foundTime;
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
		
		
		///////////PEDESTRIAN/////////////////
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
	
	action re_init {
		write "re-init people";
		walkinTime <- nil;
		searching_time<- 0;
		payment_time <- 0;
		comeback_rate_threshold <- 0.7; // assume that first happiness > 0.5
//		do add_desire(travel_to_shop);
		target <- nil;
		shopper <- false;
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
	
	action calculation_comeback { //when: every(daily#cycle){
//		write "run comeback " +opinion;

		comeback_rate <- (int(need_product) + opinion + happiness)/3;
//		write "comeback_rate " + comeback_rate;
		if  (comeback_rate >= comeback_rate_threshold) {
			
			need_product <- true;
			//TODO Hiep: randomize product list
			shopperCounts <- shopperCounts +1;
			status <- "shopping";
			shopper <- true;
			walkinTime <- time;
		}
	}
	
	// New
	action calculation_happiness {
		
	}
	// New
	action calculation_opinion {
		
	}
	//New
	action update_end_state {
		
	}
	// New 
	reflex monitor_statistic {
		
	}
	// New
	reflex monitor_search_time {
		
	}
	
	// New
	reflex monitor_current_state {
		if shopper {
			
//			if cycle >= 200 and cycle <400 {
//			status <- "counter";
////			write "cycle " +cycle;
//			}
//			if cycle >= 400 {
//				status <- "doorOut";
////				write "status " +status;
////				write "cycle " +cycle;
//			}
			searching_time <- walkinTime +patienceTime;
			if (time > searching_time){
				if (length(boughtList)>0){
					status <- "counter";
				}
			}
		
			if (length(productList)=0 and length(foundList)>0) {
				// found all product
				status <- "counter";
			}
			
			
		}
		
//	}
//		
//	reflex current_action {
		
		if status = "shopping" {
			movement <- "wander";
			do moveAround;
		}
		if status = "counter"{
//			write "status " +status;
			movement <- "counter";
			write "movement " +movement;
			do moveAround;
		}
		if status = "doorOut"{
//			write "status " +status;
			movement <- "doorOut";
			write "movement " +movement;
			do moveAround;
		}
		
		
		
	}

	
	// New
	action choose_best_product {
		
//		list<point> possible_product <- get_beliefs_with_name(prod_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
//		list<point> reject_prod <- get_beliefs_with_name(reject_prod_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
//		
//		possible_product <- possible_product - reject_prod;
//		
//		if (empty(possible_product) or (length(productList)=0 and length(foundList)>0)) {
//			write "empty product";
//			do remove_intention(found_product, true); 
//			write "choose_best_product remove_intention(found_product) ";
//		} else {
//			target <- (possible_product with_min_of (each distance_to self)).location;
//		}
//		do remove_intention(choose_product, true); 

		ask floor_cell at_distance(5.0) {
	        if(self overlaps myself) {
	            self.color <- #green;
	        }
	        
	        if(self overlaps myself) {
	            self.color <- #green;
	        }
	        
        }
		
	}
	
	// New
	action buying_decision {
		
	}
	
	// New
	action get_product {
		//find all products in list
		// if found all change do add_belief(found_product);
		movement <- "wander";
		do moveAround;
		// do check neightbor product;
		do choose_best_product;
		// do probability to buy 
		do buying_decision;
		
		// paying (optional)
		
//		if (target = nil) {
//			do choose_best_product;
//			
//		} 
//		else {
//			do goto target: target ;
//			if (target distance_to location) <=1  {
//				product_type current_product<- product_type first_with (target = each.location);
//				
//				if (current_product != nil and flip(current_product.height_chance) and length(productList)>0) {
//					
//				 	write "get_gold add_belief(has_gold) ";
////					ask current_product {quantity <- quantity - 1;}	
//
//					// TODO Hiep Option: add product to list
//					productList <- [];
//					foundList <- ["pen"];
//					boughtList <- ["pen"];
//					found_number <- found_number +1 ; 
//					// if all product is getted from this then we update belief
//					if (length(productList)=0 and length(foundList)>0){
//						
////						do add_belief(found_all_product);
//						foundTime <- time;
////						do remove_belief(found_product);
////						do remove_belief(shopping);
//
//						write "update when found all product";
//					}else{
////						do add_belief(found_product);
//					}	
//				}
//				else{
////					do add_belief(new_predicate(reject_prod_location, ["location_value"::target]));
//					write "get_product new_predicate(reject_prod_location) ";
//				}
//
//				target <- nil;
//			}}
	}




	action moveAround {
		
//		if (walkinTime !=nil and time > walkinTime +patienceTime){
		if (movement = "doorOut"){
			write "run to door out";
			if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph:network target: any_location_in(one_of(doorOut)) ;
		}
			do walk ;
		
		}
		if (movement = "counter") {
			write "run to counter";
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

