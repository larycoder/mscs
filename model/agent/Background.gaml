/**
* Name: Background
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/
model Background

/* Insert your model definition here */
global {
	shape_file free_spaces_shape_file <- shape_file("../../results/free spaces.shp");
	shape_file open_area_shape_file <- shape_file("../../results/open area.shp");
	shape_file pedestrian_paths_shape_file <- shape_file("../../results/pedestrian paths.shp");
	
	file counter_shapefile <- file("../../results/counter.shp");
	file doorIn_shapefile <- file("../../results/doorin.shp");
	file doorOut_shapefile <- file("../../results/doorout.shp");
	file floor_shapefile <- file("../../results/floor.shp");
	file shelves_shapefile <- file("../../results/shelves.shp");
	file wall_shapefile <- file("../../results/walls.shp");
	
	
	geometry open_area ;
	geometry free_space <- envelope(free_spaces_shape_file);
	geometry shape_counter <- envelope(counter_shapefile);
	geometry shape_doorIn <- envelope(doorIn_shapefile);
	geometry shape_doorOut <- envelope(doorOut_shapefile);
	geometry shape_floor <- envelope(floor_shapefile);
	geometry shape_wall <- envelope(wall_shapefile);
	
	graph network;
	//World shape
	geometry shape <- envelope(wall_shapefile);
	
	// const
//	string DOOR_IN <- "door_in" const: true;
//	string DOOR_OUT <- "door_out" const: true;

	// store
	float P_shoulder_length <- 0.45;	
	
	
	
	init {
		geometry shape <- envelope(wall_shapefile);
		create shelves from: shelves_shapefile;
		open_area <- first(open_area_shape_file.contents);
		create floors from:open_area_shape_file {
			shape <- open_area;
		}
		create pedestrian_path from: pedestrian_paths_shape_file {
			list<geometry> fs <- free_spaces_shape_file overlapping self;
			free_space <- fs first_with (each covers shape); 
		}
		network <- as_edge_graph(pedestrian_path);
		ask pedestrian_path parallel: true{
			do build_intersection_areas pedestrian_graph: network;
		}
		create counter from:counter_shapefile;
		create doorIn from:doorIn_shapefile;
		create doorOut from:doorOut_shapefile;
	}
	// if want to have red dot at mouse point, add this to mouse_move event
	action follow_mouse {
		if (length(mouse_zone) = 0) {
			create mouse_zone;
		}

		ask mouse_zone {
			location <- #user_location;
		}

	}

}

species pedestrian_path skills: [pedestrian_road] {

	aspect default {
		draw shape color: #black;
	}

	aspect free_area_aspect {
		if (free_space != nil) {
			draw free_space color: #lightpink border: #black;
		}

	}

}

species floors {

	aspect default {
		draw shape color: #pink;
	}

}

species counter {
	aspect default {
		draw shape color: rgb (128, 64, 3) border: #red;
	}
}

species shelves {
	rgb color <- #brown;

	aspect default {
		draw shape color: color;
	}

}

species wall {
	geometry free_space;
	float high <- rnd(10.0, 20.0);

	aspect demo {
		draw shape border: #black depth: high texture: ["../../includes/top.png", "../../includes/texture5.jpg"];
	}

	aspect default {
		draw shape + (P_shoulder_length / 2.0) color: #gray border: #black;
	}

}

//species door {
//	string door_type <- DOOR_IN;
//
//	aspect default {
//		draw shape color: door_type = DOOR_IN ? #green : #navy border: #black;
//	}
//
//}

species doorIn {
	aspect default {
		draw shape border:#black color:#green;
	}
}

species doorOut {
	aspect default {
		draw shape color: #navy border: #black;
	}
}

grid floor_cell width: shape.width height: shape.height neighbors: 8 {
	
	int color_value <- 0;
	init{
		color <- #black;
	}
	reflex update_color {
    if (color_value = 0) {
        color <- #green;
    } else if (color_value = 1) {
        color <- #yellow;
    } else if (color_value = 2) {
        color <- #red;
    }
    color_value <- 0;
    }
    
	aspect default {
		draw shape wireframe: true border: color;
	}

}

// special species tracking mouse point to overcome linux mouse position error
species mouse_zone {

	aspect default {
		draw circle(1 #dm) color: #red;
	}

}

experiment gui_background_example type: gui {

	init {
//		create pedestrian_path from: pedestrian_paths_file;
//		create floors from: open_area_file;
		create shelves from: shelves_shapefile;
//		create wall from: wall_shape_file;
		open_area <- first(open_area_shape_file.contents);
		create floors from:open_area_shape_file {
			shape <- open_area;
		}
		
		create pedestrian_path from: pedestrian_paths_shape_file {
			list<geometry> fs <- free_spaces_shape_file overlapping self;
			free_space <- fs first_with (each covers shape); 
		}
		network <- as_edge_graph(pedestrian_path);
		ask pedestrian_path parallel: true{
			do build_intersection_areas pedestrian_graph: network;
		}

		create counter from:counter_shapefile;
		create doorIn from:doorIn_shapefile;
		create doorOut from:doorOut_shapefile;

	}

	output {
		display background {
			species floors;
			species pedestrian_path;
			species wall;
			species shelves;
			species doorIn;
			species doorOut;
			species floor_cell;
			
		}

	}

}