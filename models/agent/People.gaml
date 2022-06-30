/**
* Name: People
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model People

import "Background.gaml"

/* Insert your model definition here */

global {
	geometry shape <- envelope(wall_shape_file);

	// pedestrian strategy parameters
	float P_shoulder_length <- 0.45;
	float P_proba_detour <- 0.5;
	bool P_avoid_other <- true;
	float P_obstacle_consideration_distance <- 3.0;
	float P_pedestrian_consideration_distance <- 3.0;
	float P_tolerance_target <- 0.1;
	bool P_use_geometry_target <- true;
	
	string P_model_type <- "simple" among: ["simple", "advanced"] parameter: true; 

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
}

species people skills: [ pedestrian ] {
	rgb color <- #blue;
	geometry shape <- circle(10);
	float speed <- gauss(5, 1.5)#km/#h min: 2#km/#h;
	
	geometry my_open_area <- nil;
	graph my_network <- nil;
	
	init {
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
	
	reflex move {
		if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph: my_network target: any_location_in(my_open_area);
		}
		do walk;
	}

	aspect default {
		draw circle(0.5) color: color;
	}
	
	aspect advance {
		if minimal_distance > 0 {
			draw circle(minimal_distance).contour color: color;
		}
		
		draw triangle(shoulder_length) color: color rotate: heading + 90.0;
		
		if current_waypoint != nil {
			draw line([location,current_waypoint]) color: color;
		}
		
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

experiment people_agent {
	init {
		create people number: 10;
	}
	
	output {
		display people_agent {
			species people;	
		}
	}
}