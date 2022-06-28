/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Productsonshelf

/* Insert your model definition here */

global{
    float max_range <- 5.0;
    int number_of_agents <- 5;
    
    
    bool display_free_space <- false parameter: true;
	bool display_force <- true parameter: true;
	bool display_target <- true parameter: true;
	bool display_circle_min_dist <- true parameter: true;
	
	float P_shoulder_length <- 0.45 parameter: true;
	float P_proba_detour <- 0.5 parameter: true ;
	bool P_avoid_other <- true parameter: true ;
	float P_obstacle_consideration_distance <- 3.0 parameter: true ;
	float P_pedestrian_consideration_distance <- 3.0 parameter: true ;
	float P_tolerance_target <- 0.1 parameter: true;
	bool P_use_geometry_target <- true parameter: true;
	
	
	string P_model_type <- "simple" among: ["simple", "advanced"] parameter: true ; 
	
	float P_A_pedestrian_SFM_advanced parameter: true <- 0.16 category: "SFM advanced" ;
	float P_A_obstacles_SFM_advanced parameter: true <- 1.9 category: "SFM advanced" ;
	float P_B_pedestrian_SFM_advanced parameter: true <- 0.1 category: "SFM advanced" ;
	float P_B_obstacles_SFM_advanced parameter: true <- 1.0 category: "SFM advanced" ;
	float P_relaxion_SFM_advanced  parameter: true <- 0.5 category: "SFM advanced" ;
	float P_gama_SFM_advanced parameter: true <- 0.35 category: "SFM advanced" ;
	float P_lambda_SFM_advanced <- 0.1 parameter: true category: "SFM advanced" ;
	float P_minimal_distance_advanced <- 0.25 parameter: true category: "SFM advanced" ;
	
	float P_n_prime_SFM_simple parameter: true <- 3.0 category: "SFM simple" ;
	float P_n_SFM_simple parameter: true <- 2.0 category: "SFM simple" ;
	float P_lambda_SFM_simple <- 2.0 parameter: true category: "SFM simple" ;
	float P_gama_SFM_simple parameter: true <- 0.35 category: "SFM simple" ;
	float P_relaxion_SFM_simple parameter: true <- 0.54 category: "SFM simple" ;
	float P_A_pedestrian_SFM_simple parameter: true <-4.5category: "SFM simple" ;
	
	// Generate path params
	float simplification_dist <- 0.5; //simplification distance for the final geometries
	bool add_points_open_area <- true;//add points to open areas
 	bool random_densification <- false;//random densification (if true, use random points to fill open areas; if false, use uniform points), 
 	float min_dist_open_area <- 0.1;//min distance to considered an area as open area, 
 	float density_open_area <- 0.01; //density of points in the open areas (float)
 	bool clean_network <-  true; 
	float tol_cliping <- 1.0; //tolerance for the cliping in triangulation (float; distance), 
	float tol_triangulation <- 0.1; //tolerance for the triangulation 
	float min_dist_obstacles_filtering <- 0.0;// minimal distance to obstacles to keep a path (float; if 0.0, no filtering), 
	
	
	float step <- 0.1;
    
    int nb_people <- 250;
    graph network;
    geometry open_area ;
    
    geometry shape <- envelope(wall_shapefile);
    
    init {
    	
    open_area <- copy(shape);
    create my_species number: number_of_agents;
    
    
    open_area <- first(open_area.contents);
    create wall from:wall_shapefile {
			open_area <- open_area -(shape buffer (P_shoulder_length/2.0));
		}
		
//    create pedestrian_path from: pedestrian_paths_shape_file {
//			list<geometry> fs <- free_spaces_shape_file overlapping self;
//			free_space <- fs first_with (each covers shape); 
//		}
	
	list<geometry> generated_lines <- generate_pedestrian_network([],
		[open_area],add_points_open_area,random_densification,
		min_dist_open_area,density_open_area,clean_network,
		tol_cliping,tol_triangulation,min_dist_obstacles_filtering,
		simplification_dist
	);
		
	create pedestrian_path from: generated_lines  {
			do initialize bounds:[open_area] distance: min(10.0,(wall closest_to self) distance_to self) masked_by: [wall] distance_extremity: 1.0;
		}
		
    network <- as_edge_graph(pedestrian_path);
    ask pedestrian_path {
			do build_intersection_areas pedestrian_graph: network;
		}
    
    
    create people number:nb_people{
			location <- any_location_in(one_of(open_area));
			obstacle_consideration_distance <-P_obstacle_consideration_distance;
			pedestrian_consideration_distance <-P_pedestrian_consideration_distance;
			shoulder_length <- P_shoulder_length;
			avoid_other <- P_avoid_other;
			proba_detour <- P_proba_detour;
			
			use_geometry_waypoint <- P_use_geometry_target;
			tolerance_waypoint<- P_tolerance_target;
			pedestrian_species <- [people];
			obstacle_species<-[wall];
			
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
    }
    
    reflex update {
    ask my_species {
        do wander amplitude: 180.0; 
        ask my_grid at_distance(max_range) {
        	
        if(self overlaps myself) {
            self.color_value <- 2;
        } else if (self.color_value != 2) {
            self.color_value <- 1;
        }
        
        }
    }
    ask my_grid {
        do update_color;
    }   
    }
	
	
	
}

species my_species skills:[moving] {
    float speed <- 2.0;
    aspect default {
    draw circle(1) color: #blue;
    }
}

grid my_grid width:30 height:30 {
    int color_value <- 0;
    action update_color {
    if (color_value = 0) {
        color <- #green;
    } else if (color_value = 1) {
        color <- #yellow;
    } else if (color_value = 2) {
        color <- #red;
    }
    color_value <- 0;
    }
}


species pedestrian_path skills: [pedestrian_road]{
	rgb color <- rnd_color(255);
	aspect default {
		draw shape  color: color;
	}
//	aspect free_area_aspect {
//		if(display_free_space and free_space != nil) {
//			draw free_space color: #cyan border: #black;
//		}
//	}
}

species wall {
	aspect default {
		draw shape + (P_shoulder_length/2.0) color: #gray border: #black;
	}
}

species people skills: [pedestrian]{
	rgb color <- rnd_color(255);
	float speed <- gauss(5,1.5) #km/#h min: 2 #km/#h;

	reflex move  {
		if (final_waypoint = nil) {
			do compute_virtual_path pedestrian_graph:network target: any_location_in(open_area) ;
		}
		do walk ;
	}	
	
	aspect default {
		
//		if display_circle_min_dist and minimal_distance > 0 {
//			draw circle(minimal_distance).contour color: color;
//		}
		
		draw triangle(shoulder_length) color: color rotate: heading + 90.0;
		
		if current_waypoint != nil {
			draw line([location,current_waypoint]) color: color;
		}
		if  true {
			loop op over: forces.keys {
				if (species(agent(op)) = wall ) {
					draw line([location, location + point(forces[op])]) color: #red end_arrow: 0.1;
				}
				else if ((agent(op)) = self ) {
					draw line([location, location + point(forces[op])]) color: #blue end_arrow: 0.1;
				} 
				else {
					draw line([location, location + point(forces[op])]) color: #green end_arrow: 0.1;
				}
			}
		}	
	}
}


experiment MyExperiment type: gui {
    output {
        display MyDisplay type: java2D {
            grid my_grid lines: #black;
            species my_species aspect: default; 
        }
    }
}