/**
* Name: People
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model People

import "Background.gaml"
import "Product.gaml"

/* Insert your model definition here */

global {
	shape_file counter_shape_file <- shape_file("../results/counter.shp");

	geometry shape <- envelope(wall_shape_file);

	// pedestrian strategy parameters
	float P_shoulder_length <- 0.45;
	float P_proba_detour <- 0.5;
	bool P_avoid_other <- true;
	float P_obstacle_consideration_distance <- 3.0;
	float P_pedestrian_consideration_distance <- 3.0;
	float P_tolerance_target <- 0.1;
	bool P_use_geometry_target <- true;
	
	string P_model_type <- "simple" among: ["simple", "advanced"];

	float P_A_pedestrian_SFM_advanced <- 0.16 category: "SFM advanced";
	float P_A_obstacles_SFM_advanced <- 1.9 category: "SFM advanced";
	float P_B_pedestrian_SFM_advanced <- 0.1 category: "SFM advanced";
	float P_B_obstacles_SFM_advanced <- 1.0 category: "SFM advanced";
	float P_relaxion_SFM_advanced  <- 0.5 category: "SFM advanced";
	float P_gama_SFM_advanced <- 0.35 category: "SFM advanced";
	float P_lambda_SFM_advanced <- 0.1 category: "SFM advanced";
	float P_minimal_distance_advanced <- 0.25 category: "SFM advanced";
	
	float P_n_prime_SFM_simple <- 3.0 category: "SFM simple";
	float P_n_SFM_simple <- 2.0 category: "SFM simple";
	float P_lambda_SFM_simple <- 2.0 category: "SFM simple";
	float P_gama_SFM_simple <- 0.35 category: "SFM simple";
	float P_relaxion_SFM_simple <- 0.54 category: "SFM simple";
	float P_A_pedestrian_SFM_simple <-4.5category: "SFM simple";
	
	// display option
	bool display_target <- false;
	bool display_force <- false;
	
	// person	
	int daily <- 600;
	
	// shop monitor
	int total_shopping_people;
	int total_buying_people;
	int total_revenue;
}

/*
 * Special person to control proudct ( does not need to present in gui ).
 */
species product_owner {
	// stategy to decide product height
	action arrange_product_height {
		// compute flip percentage for product arrangement strategy
		ask product_type { do update_order_param_part_1; }
		ask product_type { do update_order_param_part_2; }

		// normalize flip percentage
		list<float> flip_percent_list <- product_type collect each.flip_percent;
		float min_flip <- min(flip_percent_list);
		float max_flip <- max(flip_percent_list);
		float range_flip <- max_flip - min_flip;
		
		// update height of product
		ask product_type {
			flip_percent <- (flip_percent - min_flip) / range_flip;
			do update_height;
		}
	}
	
	action arrange_product_by_player {
		string high_level <- choose("High-level", string, "cheap", ["high", "medium", "low"]);
		string eye_level <- choose("Eye-level", string, "expensive", ["high", "medium", "low"]);
		string low_level <- choose("Low-level", string, "medium", ["high", "medium", "low"]);
		map selector <- user_input_dialog("Choose the strategy", [high_level, eye_level, low_level]);
		
		ask product_type {
			if (price_type = (selector at "High-level")) {
				height <- "high";
			} else if (price_type = (selector at "Eye-level")) {
				height <- "eye";
			} else {
				height <- "low";
			}
		}
	}
	
	// link product together
	action create_product_link {
		loop times: length(product_type)/2 {
			product_type pr1 <- one_of(product_type);
			product_type pr2 <- one_of(list(product_type) - pr1);
			
			create product_link  {
				add edge (pr1, pr2, self) to: product_graph;
				shape <- link(pr1,pr2);
				ask pr1 { if not (my_links contains pr2) {my_links << pr2;} }
				ask pr2 { if not (my_links contains pr1) {my_links << pr1;} }
			}
		}
	}
}


species counter {
	int round_shopping_people;
	int round_buying_people;
	int round_revenue;

	aspect default {
		draw shape color: rgb (128, 64, 3) border: #red;
	}
}


species dummy_people skills: [ pedestrian ] {
	// person attribute parameter
	rgb color <- #blue;
	geometry shape <- circle(10);
	float speed <- 1 #km/#h min: 1 #km/#h;
	
	// store parameter
	geometry my_open_area <- nil;
	graph my_network <- nil;
	door my_doorOut <- nil;
	door my_doorIn <- nil;
	
	// shopping attribute
	float walkinTime <- 0.0;
	float patience_time <- 24 #hour;
	float view_dist <- 3.0;
	
	// buying activity
	bool is_bought <- false;
	bool is_shopping <- false;
	bool is_leave <- false;
	list<product_type> product_list;

	// emotion
	// TODO: comming soon
	float opinion <- 0.0;
	float happiness <- 0.0;
	float comeback_rate_threshold <- 0.7;
	
	// my friend
	// TODO: comming soon
	list<dummy_people> friends;
	
	init {
		// pedestrian setup
		obstacle_consideration_distance <-P_obstacle_consideration_distance;
		pedestrian_consideration_distance <-P_pedestrian_consideration_distance;
		shoulder_length <- P_shoulder_length;
		avoid_other <- P_avoid_other;
		proba_detour <- P_proba_detour;
		use_geometry_waypoint <- P_use_geometry_target;
		tolerance_waypoint<- P_tolerance_target;
		pedestrian_species <- [dummy_people];
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
		
		// product setup
		product_list <- rnd(1, length(product_type)) among product_type;
	}
	
	reflex view_products when: not empty(product_type at_distance view_dist) and not empty(product_list) {
		list<product_type> viewed <- product_type at_distance view_dist;
		product_type target <- one_of(viewed where(each in product_list));
		if target != nil {
			product_list <- product_list where(each != target);
			ask counter {
				round_revenue <- round_revenue + target.price;
				total_revenue <- total_revenue + target.price;
				myself.is_bought <- true;
			}
		}
	}

	reflex move {
		if ((walkinTime != nil and time > walkinTime + patience_time) or empty(product_list)) {
			if (final_waypoint = nil) {
				do compute_virtual_path pedestrian_graph: my_network target: any_location_in(one_of(my_doorOut));
			}
			is_shopping <- false;
		} else {
			if (final_waypoint = nil) {
				do compute_virtual_path pedestrian_graph: my_network target: any_location_in(my_open_area);
			}
		}
		do walk;
	}
	
	reflex leave when: not is_shopping and not is_leave {
		is_leave <- true;
		ask counter {
			if (myself.is_bought) {
				round_buying_people <- round_buying_people + 1;
				total_buying_people <- total_buying_people + 1;
			}
		}
	}
	
	reflex comeback when: every(daily#cycle) {
		if (flip(0.5)) {
			location <- any_location_in(my_doorIn);
			is_bought <- false;
			is_leave <- false;
			is_shopping <- true;
			walkinTime <- time;
			product_list <- rnd(1, length(product_type)) among product_type;
			ask counter {
				round_shopping_people <- round_shopping_people + 1;
				total_shopping_people <- total_shopping_people + 1;
			}			
		}
	}

	aspect default {
		draw circle(0.5) color: color;
	}
	
	aspect advance {
		if minimal_distance > 0 {
			draw circle(minimal_distance).contour color: color;
		}
		
		draw circle(view_dist) color: color border: #black wireframe: true;
		draw triangle(shoulder_length) color: color rotate: heading + 90.0;
		
		if display_target and current_waypoint != nil {
			draw line([location,current_waypoint]) color: color;
		}
		
		if display_force {
			loop op over: forces.keys {
				if (species(agent(op)) = wall) {
					draw line([location, location + point(forces[op])]) color: #red end_arrow: 0.1;
				} else if ((agent(op)) = self) {
					draw line([location, location + point(forces[op])]) color: #blue end_arrow: 0.1;
				} else {
					draw line([location, location + point(forces[op])]) color: #green end_arrow: 0.1;
				}
			}
		}
	}
}

experiment people_agent {
	// TODO: counter and proudct_owner
	init {
		create dummy_people number: 10;
	}
	
	output {
		display people_agent {
			species dummy_people;	
		}
	}
}