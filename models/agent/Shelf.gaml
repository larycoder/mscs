/**
* Name: Shelf
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Shelf

/* Insert your model definition here */

global {
	geometry shape <- square(1000);
}

species Shelf {
	float deg <- rnd(0.0, 180.0);

	aspect default {
		draw rectangle(100, 50) color: #red rotate: deg;
	}
}

experiment shelf_agent {
	init {
		create Shelf number: 10;		
	}

	output {
		display shelf_agent {
			species Shelf;
		}
	}
}