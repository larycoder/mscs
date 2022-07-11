/**
* Name: SuperPeople
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model SuperPeople

import "Background.gaml"
import "Product.gaml"
import "People.gaml"

/* Insert your model definition here */

global {
	int daily <- 600 ; //cycles / day
 	int numberOfDays <- 0;

	graph friendship_graph <- graph([]);
	float first_customers_rate <- 0.1 ; // 10% of population	

	float patienceTime_global <- 600.0 #cycle;// 5.0 #minute ; 
	string prod_at_location <- "prod_at_location";
	string reject_prod_location <- "reject_prod_location";
	
	predicate travel_to_shop <- new_predicate("want to shopping ");
	
	predicate shopping <- new_predicate(" have target product "); 
	predicate saw_product <- new_predicate(prod_at_location);
	predicate choose_product <- new_predicate("choose a product"); 
	
	predicate found_product <- new_predicate("found one target product");
	predicate found_all_product <- new_predicate("found all target product");
	
	predicate loose_patience <- new_predicate("cannot found target product");
	predicate need_pay <- new_predicate ("picked some products");
	predicate need_leave <- new_predicate ("leave");
	predicate spread_rumors <- new_predicate ("recommend to friends");
}

species people skills: [pedestrian, moving] parallel: true control:simple_bdi{
	rgb color <- rnd_color(255);
	float speed <- gauss(1,0.1) #km/#h min: 0.1 #km/#h;
	point target ;
	point friend_map <- any_location_in(world);
	string movement <- "wander";
	bool shopper <- false;
	
	float patienceTime <-  30#minute ;
	float walkinTime;
	float searching_time<- 0.0;
	float counting_time;
	float payment_time <- 0.0;
	
	bool need_product <- false;
	list<product_type> productList;

	// shopping space
	graph my_network;
	geometry my_open_area;

	list<point> checkProd;
	list<product_type> boughtList <- [];
	list<product_type> foundList <- [];
	int found_number <-0;
	float foundTime ;
	float view_dist<-5.0; //dist seeing the product
	float pick_dist<-1.0; //dist to pick the product
	
	list<people> friends;
	float converge <- rnd(0.0,1.0);
	float rumor_threshold <-0.2;	
	float opinion <- 0.0 max:1.0;
	
	float happiness <- 0.0 min: 0.0 max:1.0;
	
	float comeback_rate_threshold <-0.6 min: 0.6; // as first opinion is 0.8

	// probability of go shopping
	float comeback_rate <- (float(need_product) + opinion + happiness)/3 max:1.0;
	
	init {
		friends <- list<people>(friendship_graph neighbors_of (self));
		patienceTime <- patienceTime_global;
		obstacle_consideration_distance <- P_obstacle_consideration_distance;
		pedestrian_consideration_distance <- P_pedestrian_consideration_distance;
		shoulder_length <- P_shoulder_length;
		avoid_other <- P_avoid_other;
		proba_detour <- P_proba_detour;
		use_geometry_waypoint <- P_use_geometry_target;
		tolerance_waypoint <- P_tolerance_target;
		pedestrian_species <- [people];
		obstacle_species <- [wall];
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
		searching_time<- 0.0;
		payment_time <- 0.0;
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

	if (self.name in myself.productList){
	
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
			productList <- rnd(1, length(product_type)) among product_type;
			
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
					foundList << one_of(product_type where(each.location = target));
	
					boughtList <- [];
					ask foundList {
						myself.boughtList << self;
						myself.boughtList <- myself.boughtList + self.my_links;
					}

					found_number <- found_number +1 ; 
					// if all product is getted from this then we update belief
					if (length(productList)=0 and length(foundList)>0){
						
						do add_belief(found_all_product);
						foundTime <- time;
						do remove_belief(found_product);
						do remove_belief(shopping);
						do remove_intention(found_product, true);
						do remove_intention(shopping, true);
						write "update when found all product";
					} else { do add_belief(found_product); }	
				}
				else{
					do add_belief(new_predicate(reject_prod_location, ["location_value"::target]));
					write "get_product new_predicate(reject_prod_location) ";
				}

				target <- nil;
			}}	}
	

	plan leave intention: need_leave {
		if self in agents_overlapping(one_of(door where(each.door_type = DOOR_OUT)))  {
			do remove_intention(need_leave, true);
			do remove_intention(shopping, true);
			do remove_intention(found_product, true); 
			do remove_intention(choose_product, true);
		}
		else{
			write "door OUT";
			movement <- "doorOut";
			do moveAround;
		}
	}
	
	plan pay intention: need_pay {
		// if run out of patience time do add_belief(loose_patience);
		// out of patience and bought some products do add_belief(need_pay);
		// out of patience and bought do add_belief(need_leave);	
		write "need pay";
		if (shopper){	
			movement <- "counter";
			do moveAround;
		}
		
		if  self in agents_overlapping(counter) {// (target distance_to location)<=1  {
			if counting_time =0 or counting_time =nil {
				counting_time <- float(cycle);
			}
			
			do remove_belief(found_product);
			do remove_belief(found_all_product);
			write "paying ";
//			do remove_intention(need_pay, true);
			
			//TODO Hiep Optional: add value price to sale number
			//TODO: stand and waiting for payment speed
			
		
		payment_time <- int(counting_time + length(boughtList)*10); //cycle
		write "payment_time " + payment_time; 
		write "counting_time " + counting_time; 
		write " cycle " + cycle;
		if cycle >= payment_time {
			do add_desire(need_leave);
			shopper <- false ; 
			write "done paid";
			do remove_intention(need_pay, true); 
		}
		}
	}
	
	reflex search_time {
		searching_time <- walkinTime +patienceTime;
		if (time > searching_time){
//			write "loose patience";
			do add_desire(loose_patience);
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
			bought_per_shoppingList <- 0.0;
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
			write "run to door out";
			if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph: my_network target: any_location_in(one_of(door where(each.door_type = DOOR_OUT))) ;
		}
			do walk ;
		
		}
		if (movement = "counter") {
			write "run to counter";
			if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph: my_network target: any_location_in(one_of(counter)) ;
		}
			do walk ;
		}
		if (movement = "wander"){
			if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph: my_network target: any_location_in(my_open_area) ;
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
	float recommendation;
	rgb my_color;
	
	aspect base{
		draw line([origin,recommendation],50.0) color: my_color;
	}
}

experiment super_people_agent {
	init {
		create people number: 10;
	}
	
	output {
		display people_agent {
			species people;	
		}
	}
}