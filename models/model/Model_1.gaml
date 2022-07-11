/**
* Name: Model1
* Based on the internal empty template. 
* Author: hieplnc
* Tags: 
*/


model Model1

import "../agent/Background.gaml"
import "../agent/People.gaml"
import "../agent/SuperPeople.gaml"
import "../agent/Product.gaml"

/* Insert your model definition here */

global {
	// store map
	geometry shape <- envelope(wall_shape_file);
	
	// walking space
	geometry open_area <- first(open_area_file.contents);
	graph network;

	// number of agents
	int nb_people <- 5;
	
	// simulation setup
	float step <- 1 #second;
	int daily <- 600;
	int number_of_day <- 0;
	
	init {
		create floors from: open_area_file;
		create shelf from: shelves_shape_file;
		create counter from: counter_shape_file;
		create wall from: wall_shape_file;
		create door from: door_in_shape_file { door_type <- DOOR_IN; }
		create door from: door_out_shape_file { door_type <- DOOR_OUT; }
		create product_owner number: 1;
	
		create pedestrian_path from: pedestrian_paths_file {
			list<geometry> fs <- free_spaces_shape_file overlapping self;
			free_space <- fs first_with (each covers shape);
		}
		network <- as_edge_graph(pedestrian_path); // load walking network
		
		create product_type from: product_data_file {
			location <- any_location_in(one_of(shelf));
		}

		create dummy_people number: 0 {
			my_open_area <- open_area;
			my_network <- network;
			my_doorOut <- one_of(door where(each.door_type = DOOR_OUT));
			my_doorOut <- one_of(door where(each.door_type = DOOR_IN));
			location <- any_location_in(one_of(door where(each.door_type = DOOR_IN)));
		}
		
		create people number: nb_people {
			my_open_area <- open_area;
			my_network <- network;
			location <- any_location_in(one_of(door where(each.door_type = DOOR_IN)));
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

		ask pedestrian_path parallel: true {			
			do build_intersection_areas pedestrian_graph: network;
		}

		ask product_owner {
			do create_product_link;
			do arrange_product_height;
			//do arrange_product_by_player;
		}
	}
}

experiment simple_product_shelf {
	output {
		display simple_product_shelf {
			species floors;
			species pedestrian_path refresh: false;
			species wall refresh: false;
			species counter refresh: false;
			species shelf;
			species product_type;
			species door;
			species people;
		}

		monitor revenue value: total_revenue;
		monitor shopping_people value: total_shopping_people;
		monitor buying_people value: total_buying_people;
	}
}