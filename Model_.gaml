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
import "agent/People.gaml"
import "agent/Reputation.gaml"



global {
	shape_file free_spaces_shape_file <- shape_file("results/free spaces.shp");
	file shelves_shapefile <- file("results/shelves.shp");
	file wall_shapefile <- file("results/walls.shp");
	shape_file open_area_shape_file <- shape_file("results/open area.shp");
	shape_file pedestrian_paths_shape_file <- shape_file("results/pedestrian paths.shp");
	graph network;
	geometry shape <- envelope(wall_shapefile);

	
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
	 action update_display {
	 	
	 }
	 
	 // New
	 action update_profit {
	 	
	 }
	 
	 // New
	 action update_reputation {
	 	
	 }
	 
	 // New
	 action re_init_all {
	 	
	 }
		
	 
	 // New
	 action calculation_end_of_day {
	 	
	 	// TODO: calculation profit
	 	do update_profit;
	 	// TODO: update reputation
	 	do update_reputation;
	 	// TODO: re-init params
	 	do re_init_all;
	 	
	 	if not run_business {
	 		ask world {
	 			do resume;
	 		}
	 	}
	 	
	 	days <- days + 1;
		do update_display;
		if days > end_of_game {
			do pause;
		}
	 }
	 
	 // New
	 reflex running when: run_business {
	 	
	 	
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

grid my_grid {
	
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
 