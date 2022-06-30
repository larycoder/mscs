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
	shape_file free_spaces_shpae_file <- shape_file("../results/free spaces.shp");
	shape_file shelves_shape_file <- shape_file("../results/shelves.shp");
	shape_file wall_shape_file <- shape_file("../results/walls.shp");
		
	geometry shape <- envelope(open_area_file);
}

species pedestrian_path skills: [pedestrian_road] {
	aspect default { 
		draw shape  color: #blue;
	}
}

species floors {
	aspect default {
		draw shape color:#pink;
	}
}

species shelf {
	rgb color <- #grey;

	aspect default {
		draw shape color: color;
	}
}

species wall {
	aspect default {
		draw shape color: #red border: #black;
	}
}

experiment background {
	init {
		create pedestrian_path from: pedestrian_paths_file;
		create floors from: open_area_file;
		create shelf from: shelves_shape_file;
		create wall from: wall_shape_file;
	}
	
	output {
		display background {
			species floors;
			species pedestrian_path;
			species wall;
			species shelf;
		}
	}
}