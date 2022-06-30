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
}

species people skills: [ pedestrian ] {
	rgb color <- #blue;
	geometry shape <- circle(10);
	float speed <- gauss(5, 1.5)#km/#h min: 2#km/#h;
	
	geometry my_open_area <- nil;
	graph my_network <- nil;
	
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