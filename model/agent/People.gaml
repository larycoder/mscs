/**
* Name: People
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model People
import "../parameters.gaml"
import "../Main.gaml"


global{
	///////////PEDESTRIAN/////////////////
	bool display_free_space <- false parameter: true;
	bool display_force <- true parameter: true;
	bool display_target <- false parameter: true;
	bool display_circle_min_dist <- true parameter: true;
	
	float P_shoulder_length <- 0.45 parameter: true;
	float P_proba_detour <- 0.5 parameter: true ;
	bool P_avoid_other <- false parameter: true ;
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
	
	geometry shape <- envelope(wall_shapefile);
	
	
	
}

species people skills: [pedestrian, moving] parallel: true{
	
	
	
	// assign from global
	float opinion max:1.0;
	float happiness <- 0.0;
	int expensive_tolerance <-3;
	float price_happines <-1 ;
	
	floor_cell cell;
	
	rgb color <- rnd_color(255);
	float speed <- gauss(3,2) #km/#h min: 2 #km/#h;
	
	point target ;
	point friend_map <- any_location_in(world);
	string movement <- "wander";
	string status <- "idle";
	bool shopper <- false;
	
	
	float walkinTime;
	float searching_time<- 0;
	float counting_time;
	float payment_time <- 0;
	
	bool need_product <- false;
	list<string> productList <- rnd(1, length(total_product_list)) among total_product_list;

	int needNumber <- length(productList);

	map<string,int> boughtList <- []; // "price_type"::price

	list<product_type> foundList <- [];
	
	int found_number ;
	float bought_per_shoppingList ;
	float foundTime;
	
	

	float money_spend <- 0.0;
	list<people> friends;
	
	
	// probability of go shopping
	float comeback_rate <- (float(need_product) + opinion + happiness)/3 max:1.0;
	
	init{
		// friends <- list<people>(friendship_graph neighbors_of (self));
		
		
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
			minimal_distance <- product_scanning_range; // P_minimal_distance_advanced;
		
			}
	}
	
	
	
	action make_friends {
		friends <- list<people>(friendship_graph neighbors_of (self));
	}
	
	action calculation_comeback {
//		write "run comeback " +opinion;
		write "======== Calculate comeback: " +name+ " ==========";
		write "need_product "+need_product;
		write "opinion "+opinion;
		write "happiness "+happiness;
		write "found_number: " + found_number ;
		write "needNumber: " + needNumber ;
		write "bought_per_shoppingList: " + bought_per_shoppingList ;
		write "price_happines: " + price_happines ;
		write "All time money_spend : " + money_spend;
		comeback_rate <- (int(need_product) + opinion + happiness)/3;
		write "comeback_rate " + comeback_rate;
		if  (comeback_rate >= comeback_rate_threshold) {
			
			need_product <- true;
			
			shopperCounts <- shopperCounts +1;
			status <- SHOPPING;
			write "status "+ status;

		}else{
			status <- DONE;
		}
	}
	
	

	
	

	
	// New 
	reflex monitor_statistic {
		
	}
	
	// New
	reflex monitor_search_time {
		
	}
	
	// New
	reflex _MAIN_monitor_current_state {
		
		/*We can simplify the model by making days running continuosly not stop or pause. Only pause by game rule and setup */

		// do at begining of each day
		if newDay = true{
//			write"New day _people";
//			status <- DONE;
			// Do all end day calculation here
//			do pay;
//			do population_calculation;
//			do calculation_comeback;

			
		} else {
			// Do all new day calculation here
			
//			if need_product = true {
//				status <- SHOPPING;
//			}
			
			
			
			//Movement actions by status
			if status = SHOPPING {
				movement <- "wander";
				do moveAround;
				do get_product;
//				if length (productList) =0{
//					status <- COUNTER;
////					write "empty product list";
//				}
			}
			if status = COUNTER{
//	
//				movement <- "counter";
////				write "movement " +movement;
//				do moveAround;
			}
			if status = DONE {
				
			}
		
		}
		
	}

	
	reflex update_cell_position {
    	floor_cell next_cell <- nil;
    	ask floor_cell at_distance (product_scanning_range){
		if self overlaps myself {
			next_cell <- self;
			myself.cell <- next_cell;
//			myself.my_plot.color_value <- 1;
			
		}
	}
    }
    
	// New
	action choose_best_product {
		

		if cell != nil{
    		if   (not empty (cell.neighbors)) {
    			
			list<product_place> chosen_one ;
			
			ask floor_cell at_distance (product_scanning_range){
				
				chosen_one <- product_place where ( each.cell overlaps self );	//This do the trick
//				if length(chosen_one)>0{
//					write " scanning  " + length(chosen_one);
//				}

				loop i over: chosen_one {
					i.color_code <-1;

					// Priority level:  Eye-level > top-level > lower-level
					if i.eye.type.name in myself.productList{
						add i.eye.type to: myself.foundList;
						remove i.eye.type.name from: myself.productList;
					}
					if i.high.type.name in myself.productList{
						add i.high.type to: myself.foundList;
						remove i.high.type.name from: myself.productList;
					}
					if i.low.type.name in myself.productList{
						add i.low.type to: myself.foundList;
						remove i.low.type.name from: myself.productList;
					}
					
					
				}
			}
		}
    	}
	}
	
	// New
	action buying_decision {
		
		loop i over: foundList{

			add i.price_type::i.price to: boughtList;
		}
	}
	
	// New
	action get_product {
		//find all products in list
		// if found all change do add_belief(found_product);
//		movement <- "wander";
//		do moveAround;
		// do check neightbor product;
		do choose_best_product;
		// do probability to buy 
		do buying_decision;
		

	}
	action pay{
//		money_spend
		found_number <-0;
		loop i over: boughtList.pairs{
			
			
			if i.key = "high"{
				
				expensive_tolerance <- expensive_tolerance -1;
				if expensive_tolerance >= 0 {	// Price type revert decision in here
					money_spend <- money_spend + i.value;
					found_number <- found_number +1;
					price_happines <- price_happines*high_price_happiness;
				}
			}else{
				money_spend <- money_spend + i.value;
				found_number <- found_number +1;
				if i.key = "low"{
					price_happines <- price_happines*low_price_happiness;
				}
				if i.key = "medium"{
					price_happines <- price_happines*medium_price_happiness;
				}
			}
		}
//		write "found_number pay: "+ found_number;
		
		
	}
	
	action population_calculation {
		
		
		// do by the end of the day
		do calculation_happiness;
		do spreadRumors;
//		write "found_numbe __r ___pop: " + found_number ;
		
		//TODO Update sale numbers
	} 
	


	// New
	action calculation_happiness {
		// happiness
//		float searchingTime <-  (foundTime - walkinTime)/patienceTime;
//		float paymentTime <- payment_time/patienceTime;
		
		
//		write "found_numbe __r: " + found_number ;
		if (found_number = 0){
			bought_per_shoppingList <- 0;
		}else{bought_per_shoppingList <- (found_number/needNumber);}
		
		happiness <- (bought_per_shoppingList) * price_happines;
		opinion <- opinion + _happiness_impact_to_opinion*(happiness-opinion);
	}
	
	action spreadRumors {
		
		ask friends{
			if(abs(myself.opinion-opinion) < rumor_threshold ){ //only influence if there is a opinion difference
				float temp <- opinion;
			// influencing formulae
			opinion <- opinion + (myself.opinion-opinion)*(myself.opinion-opinion)*converge;
			myself.opinion <- myself.opinion + abs(myself.opinion-temp)*abs(myself.opinion-temp)*converge;
			}
		}
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
			draw circle( 0.5, location )  color: #green; 
		}else{
			draw circle( 0.5, location )  color: #red;
		}
		
	}
	aspect default {
		
		if display_circle_min_dist and minimal_distance > 0 {
			draw circle(minimal_distance).contour color: color;
		}
		
		draw circle(product_scanning_range) color: color border: #black wireframe: true;
		
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



experiment main_people_exp type: gui {
	
	
	
	action create_population {
		// Init random need shopping people with first_customers_rate
		int need_shopping <- int(abs(first_customers_rate*nb_people));
		loop times: need_shopping {
			people p1 <- one_of(people where(each.need_product != true));
			p1.need_product <- true;
			p1.opinion <- 0.8; // init first opinion
		}
	}
	action create_friendship {
		// Create random friendship graph
		loop times: abs(nb_people*average_nb_friendPerPerson) {

			people p1 <- one_of(people);
			people p2 <- one_of(list(people) - p1);
			
			create friendship_link  {
				add edge (p1, p2, self) to: friendship_graph;
				shape <- link(p1,p2);
			}
		}
	}
	
//	list<people> friends;
	init {
		geometry shape <- envelope(wall_shapefile);
		create shelves from: shelves_shapefile;
		open_area <- first(open_area_shape_file.contents);
		create floors from:open_area_shape_file {
			shape <- open_area;
		}
		create pedestrian_path from: pedestrian_paths_shape_file {
			list<geometry> fs <- free_spaces_shape_file overlapping self;
			free_space <- fs first_with (each covers shape); 
		}
		network <- as_edge_graph(pedestrian_path);
		ask pedestrian_path parallel: true{
			do build_intersection_areas pedestrian_graph: network;
		}
		create counter from:counter_shapefile;
		create doorIn from:doorIn_shapefile;
		create doorOut from:doorOut_shapefile;
		
		create people number:nb_people {
			location <- any_location_in(one_of(doorIn));
		}
		do create_population;
		do create_friendship;
		ask people{
			
			do make_friends;
		}
		
	}		
		
		output {
		display map type: opengl{
			species wall refresh: false;
			species shelves aspect: default;
//			species counter aspect: default;
			species doorIn aspect: default;
//			species doorOut aspect: default;
//			species floor_cell;
			species people;
		}
		
		display friendship type: opengl{
			species friendship_link ;
			species people aspect: friends_default;
			}
			
		display reputation_graph refresh: every(cycle_per_day#cycle) { //refresh reputation graph daily
			
			chart "Reputation in Population" type: series  {
			loop ag over: people  {
				data ag.name value: ag.opinion color: #blue;
		}
		}
			}	
	}
}



experiment Pedestrian_exp type: gui {
	
	
	
	action create_population {
		// Init random need shopping people with first_customers_rate
		int need_shopping <- int(abs(first_customers_rate*nb_people));
		loop times: need_shopping {
			people p1 <- one_of(people where(each.need_product != true));
			p1.need_product <- true;
			p1.opinion <- 0.8; // init first opinion
		}
	}
	action create_friendship {
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
	
//	list<people> friends;
	init {
		geometry shape <- envelope(wall_shapefile);
		create shelves from: shelves_shapefile;
		open_area <- first(open_area_shape_file.contents);
		create floors from:open_area_shape_file {
			shape <- open_area;
		}
		create pedestrian_path from: pedestrian_paths_shape_file {
			list<geometry> fs <- free_spaces_shape_file overlapping self;
			free_space <- fs first_with (each covers shape); 
		}
		network <- as_edge_graph(pedestrian_path);
		ask pedestrian_path parallel: true{
			do build_intersection_areas pedestrian_graph: network;
		}
		create counter from:counter_shapefile;
		create doorIn from:doorIn_shapefile;
		create doorOut from:doorOut_shapefile;
		
		create people number:nb_people {
			location <- any_location_in(one_of(doorIn));
		}
		do create_population;
		do create_friendship;
		ask people{
			
			do make_friends;
		}
		
//		friends <- list<people>(friendship_graph neighbors_of (self));
	}
		
		reflex move {
			ask people {
				movement <- "wander";
				do moveAround;
			}
		}
		output {
		display map type: opengl{
			species wall refresh: false;
			species shelves aspect: default;
			species counter aspect: default;
			species doorIn aspect: default;
			species doorOut aspect: default;

			species people;
		}
	}
}
 
