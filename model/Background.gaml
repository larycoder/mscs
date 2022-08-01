/**
* Name: Background
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Background

/* Insert your model definition here */

global {
	shape_file pedestrian_paths_file <- shape_file("../results/pedestrian paths.shp");
	shape_file open_area_file <- shape_file("../results/open area.shp");
	shape_file free_spaces_shape_file <- shape_file("../results/free spaces.shp");
	shape_file shelves_shape_file <- shape_file("../results/shelves.shp");
	shape_file wall_shape_file <- shape_file("../results/walls.shp");
	shape_file door_in_shape_file <- shape_file("../results/doorin.shp");
	shape_file door_out_shape_file <- shape_file("../results/doorout.shp");
		
	geometry shape <- envelope(open_area_file);
	
	// const
	string DOOR_IN <- "door_in" const: true;
	string DOOR_OUT <- "door_out" const: true;
	
	// store owner
	int revenue <- 0;
	
	float P_shoulder_length <- 0.45 parameter: true;
}

species pedestrian_path skills: [pedestrian_road] {
	aspect default { 
		draw shape  color: #black;
	}
	
	aspect free_area_aspect {
		if(free_space != nil) {
			draw free_space color: #lightpink border: #black;
		}
		
	}
}

species floors {
	aspect default {
		draw shape color:#pink;
	}
}

species shelf {
	rgb color <- #brown;

	aspect default {
		draw shape color: color;
	}
}

species wall {	
	geometry free_space;
	float high <- rnd(10.0, 20.0);
	
	aspect demo {
		draw shape border: #black depth: high texture: ["../includes/top.png","../includes/texture5.jpg"];
	}
	
	aspect default {
		draw shape + (P_shoulder_length/2.0) color: #gray border: #black;
	}
}

species door {
	string door_type <- DOOR_IN;	
	
	aspect default {
		draw shape color: door_type = DOOR_IN ? #green : #navy border: #black;
	}
}

experiment background {
	init {
		create pedestrian_path from: pedestrian_paths_file;
		create floors from: open_area_file;
		create shelf from: shelves_shape_file;
		create wall from: wall_shape_file;
		create door from: door_in_shape_file { door_type <- DOOR_IN; }
		create door from: door_out_shape_file { door_type <- DOOR_OUT; }
	}
	
	output {
		display background {
			species floors;
			species pedestrian_path;
			species wall;
			species shelf;
			species door;
		}
	}
}