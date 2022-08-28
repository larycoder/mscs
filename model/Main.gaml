/**
* Name: Model
* Based on the internal empty template. 
* Author: admin
* Tags: 
*/


model Main

/* Insert your model definition here */

/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: Son Ngoc Nguyen
* Tags: 
*/

import "parameters.gaml"
import "agent/People.gaml"
import "agent/Reputation.gaml"
import "agent/Product.gaml"
import "agent/Background.gaml"


global {
//	shape_file free_spaces_shape_file <- shape_file("../results/free spaces.shp");
//	shape_file open_area_shape_file <- shape_file("../results/open area.shp");
//	shape_file pedestrian_paths_shape_file <- shape_file("../results/pedestrian paths.shp");
//	
//	file counter_shapefile <- file("../results/counter.shp");
//	file doorIn_shapefile <- file("../results/doorin.shp");
//	file doorOut_shapefile <- file("../results/doorout.shp");
//	file floor_shapefile <- file("../results/floor.shp");
//	file shelves_shapefile <- file("../results/shelves.shp");
//	file wall_shapefile <- file("../results/walls.shp");
//	
//	
//	geometry open_area ;
//	geometry free_space <- envelope(free_spaces_shape_file);
//	geometry shape_counter <- envelope(counter_shapefile);
//	geometry shape_doorIn <- envelope(doorIn_shapefile);
//	geometry shape_doorOut <- envelope(doorOut_shapefile);
//	geometry shape_floor <- envelope(floor_shapefile);
//	geometry shape_wall <- envelope(wall_shapefile);
//	
//	graph network;
//	
	//World shape
	geometry shape <- envelope(wall_shapefile);
	
	//	float step <- 0.1;
//	int remaining_time min: 0;
//	bool run_business <- false ;
//	int current_cycle <- 0 ;
	
	
//	int nb_people <- 10;
//	int nb_product <- 15;
	
	//social graph (not spatial) representing the friendship links between people
//	graph friendship_graph <- graph([]);
//	graph product_graph <- graph([]);
	
	//Time definition
	float step <- 1 #second; 
// 	int daily <- 600 ; //cycles / day
 	int numberOfDays <- 0; 
 	int prevDay <- -1;
 	int shopperCounts;
 	
 	
	
//	float patienceTime_global <- 600 #cycle;// 5.0 #minute ; 

	bool newDay <- true;
//	bool endDay <- false;

	
	init {
//		create counter from:counter_shapefile;
//		create doorIn from:doorIn_shapefile;
//		create doorOut from:doorOut_shapefile;
//		create floors from:open_area_shape_file {
//			shape <- open_area;
//		}
//		create wall from:wall_shapefile;
		
//		open_area <- first(open_area_shape_file.contents);
//		create shelves from:shelves_shapefile;
		
//		create pedestrian_path from: pedestrian_paths_shape_file {
//			list<geometry> fs <- free_spaces_shape_file overlapping self;
//			free_space <- fs first_with (each covers shape); 
//		}

//		network <- as_edge_graph(pedestrian_path);
//		ask pedestrian_path parallel: true{
//			do build_intersection_areas pedestrian_graph: network;
//		}
		
//		create people number:nb_people {
////			location <- any_location_in(one_of(open_area));
//			location <- any_location_in(one_of(doorIn));
////			write "patienceTime default " + patienceTime ;
//			patienceTime <- myself.patienceTime_global; 
//			
////			write "patienceTime " + myself.patienceTime + " " + patienceTime ;
//			
//		}	
		
//		// Init random need shopping people with first_customers_rate
//		int need_shopping <- int(abs(first_customers_rate*nb_people));
//		loop times: need_shopping {
//			people p1 <- one_of(people where(each.need_product != true));
//			
//			p1.need_product <- true;
//			p1.opinion <- 0.8; // init first opinion
//			
//		}
//		do create_population;
		
//		// Create random friendship graph
//		loop times: abs(nb_people*1.5) {
//
//			people p1 <- one_of(people);
//			people p2 <- one_of(list(people) - p1);
//			
//			create friendship_link  {
//				add edge (p1, p2, self) to: friendship_graph;
//				shape <- link(p1.friend_map,p2.friend_map);
//			}
//		}
//		do create_friendship;
		
//		create product_type number:nb_product{
//			// TODO Hiep: load from csv file
//			// TODO Hiep: heigh formula
//			name <- "pen";
//			price <- 100;
//			location <- any_location_in(one_of(shelves) );
////			linked_id <- 21;
//		}
//		
//		// create product link
//		loop times: nb_product/2 {
//			product_type pr1 <- one_of(product_type);
//			product_type pr2 <- one_of(list(product_type) - pr1);
//			
//			create product_link  {
//				add edge (pr1, pr2, self) to: product_graph;
//				shape <- link(pr1,pr2);
//			}
//		}
		
		create people number:nb_people {
			location <- any_location_in(one_of(doorIn));
			expensive_tolerance <- _expensive_tolerance;
			happiness <- _happiness;
			write "Create person " + name ;
		}
		
	}
	
	// TODO: more specific pause condition
//	reflex stop when: every(daily#cycle){ // empty(people) or (shopperCounts =0)  {
//		
//		if (numberOfDays+1 >1){
//		ask people{
////			write "Try re init";
//			do re_init;
//		} 
//		}
//		do pause;
//
//	}
	
	 
	 // New
//	 action update_display {
//	 	
//	 }
	 
	 // New
//	 action update_profit {
//	 	
//	 }
	 
	 // New
//	 action update_reputation {
//	 	
//	 }
//	 
	 // New
//	 action re_init_all {
//	 	
//	 }
		
	 
	 // New
//	 action calculation_end_of_day {
//	 	
//	 	// TODO: calculation profit
//	 	do update_profit;
//	 	// TODO: update reputation
//	 	do update_reputation;
//	 	// TODO: re-init params
//	 	do re_init_all;
//	 	
//	 	if not run_business {
//	 		ask world {
//	 			do resume;
//	 		}
//	 	}
//	 	
//	 	days <- days + 1;
//		do update_display;
//		if days > end_of_game {
//			do pause;
//		}
//	 }
	 
	 action daily_customers_need{
		// Init random need shopping people with first_customers_rate
		int dail_need_shopping <- int(abs(daily_customers_rate*nb_people));
		loop times: dail_need_shopping {
			people p1 <- one_of(people where(each.need_product != true));
			p1.need_product <- true;
			
			// TODO: making randome list of product
			ask p1 {
				productList <- rnd(1, length(total_product_list)) among total_product_list;
			}
			
			if p1.opinion =nil {
				p1.opinion <- _opinion; // init first opinion
			}
			write p1.name + " need shopping";
		}
	 }
	 
	 action comeback_for_fun{
	 	ask people {
	 		if self.opinion >= comeback_for_fun_opinion_threshold {
	 			self.need_product <- true;
	 			
	 			// TODO: making randome list of product
				
				self.productList <- rnd(1, length(total_product_list)) among total_product_list;
				write self.name + " need shopping for fun";
			
	 		}
	 	}
	 }
	 
	reflex _MAIN_ {
		
		do current_time ;
		
		// people start with status from yesterday
		
		// Pause every day to re config strategy
		if newDay = true {
			write "Day: " + numberOfDays ;
			// do all end of day calculation
			converge  <- rnd(1,10);
			if numberOfDays >0 {
				
				
				
				ask people {
					
				if need_product != nil and (need_product = true) {
						location <- any_location_in(one_of(doorOut));
					}
					
				need_product <- false;
				status <- DONE;
				}
				do daily_customers_need;
				do comeback_for_fun;
			}
			
			
			ask people {
				do calculation_comeback;
			}
			
			
			do pause;
		}
		
	}

	action current_time { //} when: every(daily#cycle) {

		// Clock

		numberOfDays <- numberOfDays + abs((cycle - numberOfDays*cycle_per_day)/cycle_per_day);


		// TODO: recalculate states'
		if numberOfDays != prevDay{
//			endDay <- true;
			newDay <- true;
		} else {
			newDay <- false;
		}

		prevDay <- numberOfDays;
	}
	
	
	 // New
//	 reflex running when: run_business {
//	 	
//	 	
//	 	do calculation_end_of_day;
//	 	current_cycle <- current_cycle +1;
//	 }
	 
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



experiment normal_sim type: gui {
	
	
	action create_population {
		// Init random need shopping people with first_customers_rate
		int need_shopping <- int(abs(first_customers_rate*nb_people));
		loop times: need_shopping {
			people p1 <- one_of(people where(each.need_product != true));
			p1.need_product <- true;
			p1.opinion <- _opinion; // init first opinion
		}
	}

	action create_friendship {
		// Create random friendship graph
		loop times: abs(nb_people*1.5) {

			people p1 <- one_of(people);
			people p2 <- one_of(list(people) - p1);
			
			create friendship_link  {
				add edge (p1, p2, self) to: friendship_graph;
				shape <- link(p1,p2);
			}
		}
	}
	
	init {
		
		
		do create_population;
		do create_friendship;
		ask people{
			
			do make_friends;
		}
	}
	output {
		display map type: opengl{
//			species floors aspect: default;
			species wall refresh: false;
			species shelves aspect: default;
//			species floor_cell;
			species counter aspect: default;
			species doorIn aspect: default;
			species doorOut aspect: default;
			
//			species pedestrian_path aspect:free_area_aspect transparency: 0.5 ;
//			species pedestrian_path refresh: false;
			species people;
//			species product_type;
			species product_place aspect: default;
			
			
			
			
		}
		display friendship type: opengl{
			species friendship_link ;
			species people aspect: friends_default;
			}
//		display product_type type: opengl{
//			species product_link ;
//			species product_type;
//			}
		display reputation_graph refresh: every(cycle_per_day#cycle) { //refresh reputation graph daily
			
			chart "Reputation in Population" type: series  {
			write "chart no of people "+ length(people);
			loop ag over: people  {
				write"chart people name "+ ag.name;
				data ag.name value: ag.opinion color: #blue;
				}
				
			}
		}
			
	}
}
 