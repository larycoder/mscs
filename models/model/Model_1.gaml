/**
* Name: Model1
* Based on the internal empty template. 
* Author: hieplnc
* Tags: 
*/


model Model1

import "../agent/Background.gaml"
import "../agent/People.gaml"
import "../agent/Product.gaml"

/* Insert your model definition here */

global {
	// store map
	geometry shape <- envelope(wall_shape_file);
	
	// walking space
	geometry open_area <- first(open_area_file.contents);
	graph network;

	// number of agents
	int nb_people <- 10;
	int nb_product <- 10;
	
	// simulation setup
	float step <- 0.1;
	
	init {
		create floors from: open_area_file;
		create shelf from: shelves_shape_file;
		create wall from: wall_shape_file;
		create door from: door_in_shape_file { door_type <- DOOR_IN; }
		create door from: door_out_shape_file { door_type <- DOOR_OUT; }
	
		create pedestrian_path from: pedestrian_paths_file {
			list<geometry> fs <- free_spaces_shape_file overlapping self;
			free_space <- fs first_with (each covers shape);
		}
		network <- as_edge_graph(pedestrian_path); // load walking network

		create people number: nb_people {
			my_open_area <- open_area;
			my_network <- network;
			location <- any_location_in(one_of(my_open_area));
		}
		
		create store_product number: nb_product {
			location <- any_location_in(one_of(shelf));
		}

		ask pedestrian_path parallel: true {			
			do build_intersection_areas pedestrian_graph: network;
		}
	}
}

experiment simple_product_shelf {
	output {
		display simple_product_shelf {
			species floors;
			species pedestrian_path refresh: false;
			species wall refresh: false;
			species shelf;
			species store_product;
			species door;
			species people aspect: advance;
		}
	}
}