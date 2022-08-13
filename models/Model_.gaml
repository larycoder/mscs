/**
* Name: Model
* Based on the internal empty template. 
* Author: admin
* Tags: 
*/


model Model

/* Insert your model definition here */

/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: Son Ngoc Nguyen
* Tags: 
*/

import "parameters.gaml"

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
	int remaining_time min: 0;
	bool run_business <- false ;
	int current_cycle <- 0 ;
	
	
	int nb_people <- 10;
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
 	int numberOfDays <- 0; 
 	int shopperCounts;
 	
 	float first_customers_rate <- 0.1 ; // 10% of population
	
	float patienceTime_global <- 600 #cycle;// 5.0 #minute ; 

	

	
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
			patienceTime <- myself.patienceTime_global; 
			
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
		
		
		create product_type number:nb_product{
			// TODO Hiep: load from csv file
			// TODO Hiep: heigh formula
			name <- "pen";
			price <- 100;
			location <- any_location_in(one_of(shelves) );
//			linked_id <- 21;
		}
		// create product link
		loop times: nb_product/2 {
			product_type pr1 <- one_of(product_type);
			product_type pr2 <- one_of(list(product_type) - pr1);
			
			create product_link  {
				add edge (pr1, pr2, self) to: product_graph;
				shape <- link(pr1,pr2);
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
	
	
//	reflex scan_product {
//		ask people{
//			ask my_grid at_distance(3) {
//	        if(self overlaps myself) {
//	            self.color_value <- 2;
//	        } else if (self.color_value != 2) {
//	            self.color_value <- 1;
//	        }
//	        }
//	}
//	}
	 
	 // New
	 action calculation_end_of_day {
	 	
	 	// TODO: calculation budget
	 	// TODO: update reputation
	 	if not run_business {
	 		ask world {
	 			do resume;
	 		}
	 	}
	 }
	 
	 // New
	 reflex profit_count when: run_business {
	 	
	 	
	 	do calculation_end_of_day;
	 	current_cycle <- current_cycle +1;
	 }
	 // New
//	 reflex end_of_day {
//	 	remaining_time <- int(time_for_a_day - machine_time/1000.0);
//	 	if remaining_time <= 0 {
//	 		do tell("End of a day!");
//			do pause;
//	 	}
//	 }
}


////////////////////////////////// END GLOBAL /////////////////////////////////////////


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
	
	reflex comeback when: every(daily#cycle){
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
	
	reflex search_time {
		
	}
	
	
	reflex current_state {
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

//	reflex move when: need_product {
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


grid my_grid {
	
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
	
	string name <-"unknown";
	
	int price;
	string PrType;
	
	// Eye-level > top-level > lower-level
	float height_chance <- 0.5; //default a random chance of buying
	
	
//	location <- any_location_in (on_of(shelves)); // and in a grid overlay, avoid location where we already has other product
//	int height one_of(["high", "eye", "low"]);
	
	aspect default {
		draw circle(0.7) color: #black;
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
 