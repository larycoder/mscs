/**
* Name: Product
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/
model Product

import "Background.gaml"

/**
 * Product shuffle strategy:
 * 
 * The product is categorized into 3 price type: high, medium and low. Also, the shelf has 3 level layout
 * which are top level, eye level and lower level. Then with each shelf layout, player could choose which
 * price type product should be placed on. After both 3 layouts are decided, program will shuffle product
 * to shelf following rule: only products matching price type of layout be chosen and if there are multiple
 * product sharing same price type, product will randomly pick out one for each shelf place.
 * 
 */
global {
	file product_data_file <- csv_file("../includes/product.csv", ",", string, true);
	geometry shape <- square(50);

	// product strategy by parameter	
	string eye_level <- "medium" among: ["low", "high", "medium"];
	string low_level <- "low" among: ["low", "high", "medium"];
	string high_level <- "high" among: ["low", "high", "medium"];

	// product order strategy
	map<string, string> strategy <- ["eye"::"medium", "high"::"high", "low"::"low"]; // default

	// product link present
	graph product_graph <- graph([]);

	init {
		create product_util number: 1; // singleton object
	}

	// mouse interaction
	product_place product_mouse;
	geometry zone <- circle(1);

	action click {
		if (product_mouse = nil) {
			product_mouse <- one_of(product_place overlapping (zone at_location #user_location));
			write "Stack product place: " + product_mouse;
		} else {
			ask product_mouse {
				do move(#user_location);
			}

			write "Pop product place: " + product_mouse;
			product_mouse <- nil;
		}

	}

}

species product_type {
	geometry shape <- circle(0.2);
	rgb color <- #yellow;
	int id;
	string name;
	string price_type;
	int price;
	list<product_type> my_links;
	int linked_id; // deprecated
}

species product_instance {
	product_type type;
	rgb color <- #black;

	action update_view {
		if (type.price_type = "medium") {
			color <- #yellow;
		} else if (type.price_type = "low") {
			color <- #green;
		} else {
			color <- #red;
		}

	}

	aspect default {
		do update_view;
		draw circle(1) color: color;
	}

	aspect three_d {
		do update_view;
		draw sphere(1) color: color;
	}

}

species product_link {

	aspect default {
		draw shape color: #orange;
	}

}

/**
 * Present a 2D place of product in shelf including 3 layout positions.
 */
species product_place {
	product_instance high;
	product_instance eye;
	product_instance low;

	action add_instance (product_instance p, string level) {
		if (level = "high") {
			high <- p;
			high.location <- {location.x, location.y, 25.0};
		} else if (level = "eye") {
			eye <- p;
			eye.location <- {location.x, location.y, 15.0};
		} else {
			low <- p;
			low.location <- {location.x, location.y, 5.0};
		}

	}

	action add_type (product_type t, string level) {
		product_instance p;
		create product_instance {
			type <- t;
			p <- self;
		}

		do add_instance(p, level);
	}

	action move (point new_location) {
		location <- new_location;
		do add_instance(high, "high");
		do add_instance(eye, "eye");
		do add_instance(low, "low");
	}

	aspect default {
		draw circle(1) color: #black;
	}

}

species product_util {

	action shuffle {
		ask product_instance {
			do die;
		}

		ask product_place {
			list<product_type> high_list <- product_type where (each.price_type = strategy["high"]);
			do add_type(one_of(high_list), "high");
			list<product_type> eye_list <- product_type where (each.price_type = strategy["eye"]);
			do add_type(one_of(eye_list), "eye");
			list<product_type> low_list <- product_type where (each.price_type = strategy["low"]);
			do add_type(one_of(low_list), "low");
		}

	}

	action get_player_strategy {
		strategy <-
		user_input_dialog("Choose the strategy", [choose("high", string, "high", ["high", "medium", "low"]), choose("eye", string, "medium", ["high", "medium", "low"]), choose("low", string, "low", ["high", "medium", "low"])]);
	}

	action get_param_strategy {
		strategy <- ["high"::high_level, "eye"::eye_level, "low"::low_level];
	}

	// link product together
	action create_product_link {
		loop times: length(product_type) / 2 {
			product_type pr1 <- one_of(product_type);
			product_type pr2 <- one_of(list(product_type) - pr1);
			create product_link {
				add edge(pr1, pr2, self) to: product_graph;
				shape <- link(pr1, pr2);
				ask pr1 {
					if not (my_links contains pr2) {
						my_links << pr2;
					}

				}

				ask pr2 {
					if not (my_links contains pr1) {
						my_links << pr1;
					}

				}

			}

		}

	}

}

experiment product_interact_example type: gui {

	init {
		create product_type from: product_data_file;
		create product_place number: 10;
		ask product_util {
			do create_product_link;
			do get_player_strategy;
			do shuffle;
		}

	}

	user_command "change strategy" {
		ask product_util {
			do get_player_strategy;
			do shuffle;
		}

	}

	output {
		display my_product type: opengl {
			species product_place;
			species product_instance aspect: three_d;
			species mouse_zone;

			// move product place by mouse
			event mouse_up action: click;
			
			// mouse zone viewer
			species mouse_zone;
			event mouse_move action: follow_mouse;
		}

	}

}

experiment product_param_example type: gui {

	init {
		create product_type from: product_data_file;
		create product_place number: 10;
		ask product_util {
			do create_product_link;
			do get_param_strategy;
			do shuffle;
		}

	}

	// generate product context
	parameter "high level" var: high_level;
	parameter "eye level" var: eye_level;
	parameter "low level" var: low_level;
	user_command "shuffle product" {
		ask product_util {
			do get_param_strategy;
			do shuffle;
		}

	}

	output {
		display my_product type: opengl {
			species product_place;
			species product_instance aspect: three_d;

			// move product place by mouse
			event mouse_up action: click;
			
			// mouse zone viewer
			species mouse_zone;
			event mouse_move action: follow_mouse;
		}

	}

}