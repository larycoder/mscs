/**
* Name: Experience
* Based on the internal empty template. 
* Author: hieplnc
* Tags: 
*/
model Experience

import "agent/Background.gaml"
import "agent/Product.gaml"
import "agent/People.gaml"
import "Main.gaml"
import "parameters.gaml"

/* Insert your model definition here */
global {
	geometry shape <- envelope(wall_shapefile);
	bool not_people <- true;

	// shop data
	float total_revenue <- 0.0;
	float total_avg_hapiness <- 0.0;
	int total_shopping_nb <- 0;
	int total_buying_nb <- 0;

	init {
		create mouse_zone;
		create people_util number: 1; // singleton object
	}

	reflex monitor_shopping when: every(cycle_per_day #cycle) {
		total_revenue <- round_revenue;
		total_shopping_nb <- total_shopping_nb + int(round_shopping_nb);
		total_buying_nb <- total_buying_nb + round_buying_nb;
		total_avg_hapiness <- total_avg_hapiness + mean(people sum_of(each.happiness));
				
		write "======== total shopping data ========";
		write "total revenue: " + total_revenue;
		write "total shopping nb: " + total_shopping_nb;
		write "total buying nb: " + total_buying_nb;
		write "total avg hapiness: " + total_avg_hapiness;
	}

}

// ############## initalize people ############## //
// NOTE: this is tricky start, avoiding it
species people_util {

	action init_people {
		not_people <- false;

		// Init random need shopping people with first_customers_rate
		int need_shopping <- int(abs(first_customers_rate * nb_people));
		loop times: need_shopping {
			people p1 <- one_of(people where (each.need_product != true));
			p1.need_product <- true;
			p1.opinion <- _opinion; // init first opinion
		}

		// Create random friendship graph
		loop times: abs(nb_people * 1.5) {
			people p1 <- one_of(people);
			people p2 <- one_of(list(people) - p1);
			create friendship_link {
				add edge(p1, p2, self) to: friendship_graph;
				shape <- link(p1, p2);
			}

		}

		// Ask people to make friend
		ask people {
			do make_friends;
			do calculation_comeback;
		}

	}

}

experiment gui_exploit {
	parameter "high level" var: high_level category: "product";
	parameter "eye level" var: eye_level category: "product";
	parameter "low level" var: low_level category: "product";
	parameter "number people" var: nb_people category: "people behavior";
	parameter "high price happiness" var: high_price_happiness category: "people behavior";
	parameter "medium price happiness" var: medium_price_happiness category: "people behavior";
	parameter "low price happiness" var: low_price_happiness category: "people behavior";
	parameter "comeback rate threshold" var: comeback_rate_threshold category: "people behavior";
	parameter "comeback for fun opinion threshold" var: comeback_for_fun_opinion_threshold category: "people behavior";
	user_command "shuffle product to places" {
		ask product_util {
			do get_param_strategy;
			do shuffle;
			write "product util [" + name + "]: shuffle product to product place";
		}

	}

	init {
		ask people_util {
			do init_people;
		}

	}

	output {
		display store_view type: opengl {
			species floors;
			species pedestrian_path;
			species wall;
			species shelves;
			species doorIn;
			species doorOut;
			species floor_cell;
			species people;
			species product_place {
				draw shape color: #black;
			}

			species product_instance aspect: three_d;

			// mouse zone viewer
			species mouse_zone;
			event mouse_move action: follow_mouse;
		}

		display timeline refresh: every(cycle_per_day #cycle) {
			chart "timeline" type: series {
				data "total revenue" value: total_revenue color: #red;
				data "total shopping number" value: total_shopping_nb color: #green;
				data "total buying number" value: total_buying_nb color: #brown;
				//data "round average hapiness" value: round_avg_hapiness color: #yellow;
			}

		}

		display reputation_graph refresh: every(cycle_per_day #cycle) { //refresh reputation graph daily
			chart "Opinions of Population" type: series {
				write "chart no of people " + length(people);
				loop ag over: people {
					write "chart people name " + ag.name;
					data ag.name value: ag.opinion color: #blue;
				}

			}

		}

		display friendship type: opengl {
			species friendship_link;
			species people aspect: friends_default;
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
			species shelves;
			species doorIn;
			species doorOut;
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
