/**
* Name: Experience
* Based on the internal empty template. 
* Author: hieplnc
* Tags: 
*/
model Experience

import "Background.gaml"
import "Product.gaml"

/* Insert your model definition here */
global {
	geometry shape <- envelope(open_area_file);

	init {
		create pedestrian_path from: pedestrian_paths_file;
		create floors from: open_area_file;
		create shelf from: shelves_shape_file;
		create wall from: wall_shape_file;
		create door from: door_in_shape_file {
			door_type <- DOOR_IN;
		}

		create door from: door_in_shape_file {
			door_type <- DOOR_OUT;
		}

		create product_type from: product_data_file;
		ask product_util {
			do create_product_link;
		}

	}

}

/*
 * Allow user to sort product place by mouse click and save their position to csv file.
 */
experiment arrange_and_store_product_position_in_csv {
	parameter "high level" var: high_level;
	parameter "eye level" var: eye_level;
	parameter "low level" var: low_level;
	user_command "add product place" {
		create product_place {
			floor_cell my_cell <- one_of(floor_cell);
			shape <- my_cell.shape;
			location <- my_cell.location;
		}

	}

	user_command "shuffle product to places" {
		ask product_util {
			do get_player_strategy;
			do shuffle;
		}

	}

	output {
		display my_store {
			species floors;
			species pedestrian_path;
			species wall;
			species shelf;
			species door;
			species floor_cell;
			species product_place {
				draw shape color: #black;
			}

			species mouse_zone;
		}

	}

}