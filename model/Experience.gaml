/**
* Name: Experience
* Based on the internal empty template. 
* Author: hieplnc
* Tags: 
*/
model Experience

import "agent/Background.gaml"
import "agent/Product.gaml"
import "parameters.gaml"

/* Insert your model definition here */
global {
	geometry shape <- envelope(open_area_file);

	// csv file for saving product_place position
	string product_place_csv <- "../results/product_place.csv";

	init {
		create mouse_zone;
		create pedestrian_path from: pedestrian_paths_file;
		create floors from: open_area_file;
		create shelf from: shelves_shape_file;
		create wall from: wall_shape_file;
		create door from: door_in_shape_file {
			door_type <- DOOR_IN;
		}

		create door from: door_out_shape_file {
			door_type <- DOOR_OUT;
		}

		create product_type from: product_data_file;
		ask product_util {
			do create_product_link;
		}

		// read product_place from csv and initialize them.
		// NOTE: if wanting to arrange product position, comment below lines
		create product_place from: csv_file(product_place_csv, ",", true) with:
		[name:: read("name"), location::{float(read("location.x")), float(read("location.y")), float(read("location.z"))}];
		ask product_place {
			cell <- one_of(floor_cell where (not empty([self] inside each)));
			shape <- cell.shape;
			location <- cell.location;
		}

		create product_util number: 1 {
			do shuffle;
			do die;
		}

	}

}

experiment gui_exploit {
	parameter "high level" var: high_level;
	parameter "eye level" var: eye_level;
	parameter "low level" var: low_level;

	user_command "shuffle product to places" {
		ask product_util {
			do get_param_strategy;
			do shuffle;
			write "product util [" + name + "]: shuffle product to product place";
		}

	}

	output {
		display timeline {
			chart "timeline" type: series {
				data "round revenue" value: round_revenue color: #red;
				data "round shopping number" value: round_shopping_nb color: #green;
				data "round buying number" value: round_buying_nb color: #brown;
				data "round average hapiness" value: round_avg_hapiness color: #yellow;
			}

		}

		display bar_value {
			chart "bar chart of values" type: histogram {
				datalist ["round revenue", "round shopping number", "round buying number", "round average hapiness"] value:
				[round_revenue, round_shopping_nb, round_buying_nb, round_avg_hapiness];
			}

		}

		display store_view type: opengl {
			species floors;
			species pedestrian_path;
			species wall;
			species shelf;
			species door;
			species floor_cell;
			species product_place {
				draw shape color: #black;
			}

			species product_instance aspect: three_d;

			// mouse zone viewer
			species mouse_zone;
			event mouse_move action: follow_mouse;
		}

	}

}

experiment batch_exploit type: batch repeat: 5 keep_seed: true until: cycle > 1000 {
	permanent {
		display "permanent" {
			chart "permanent timeline" type: series {
				data "simulation timeline" value: round_revenue color: #red;
			}

		}

	}

}

/*
 * Allow user to sort product place by mouse click and save their position to csv file.
 */
experiment arrange_and_store_product_position_in_csv {
	user_command "add product place" {
		create product_place {
			cell <- one_of(floor_cell where (empty(product_place inside each)));
			shape <- cell.shape;
			location <- cell.location;
		}

	}

	user_command "save product place position to csv" {
		bool ret <- delete_file(product_place_csv);
		ask product_place {
			save [name, location.x, location.y, location.z] to: product_place_csv type: csv rewrite: false;
		}

		write "Save product place position to file: " + product_place_csv;
	}

	output {
		display my_store type: opengl {
			species floors;
			species pedestrian_path;
			species wall;
			species shelf;
			species door;
			species floor_cell;
			species product_place {
				draw shape color: #black;
			}

			// move product place by mouse
			event mouse_up action: click;

			// mouse zone viewer
			species mouse_zone;
			event mouse_move action: follow_mouse;
		}

	}

}
