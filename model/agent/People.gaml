/**
* Name: People
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model People

/* Insert your model definition here */

global {
	shape_file counter_shape_file <- shape_file("../results/counter.shp");

	// shop monitor
	int total_shopping_people;
	int total_buying_people;
	int total_revenue;
	
	init {
		create counter number: 1; // singleton object
	}
}

species counter {
	int round_shopping_people;
	int round_buying_people;
	int round_revenue;
	
	aspect default {
		draw shape color: #brown;
	}
}