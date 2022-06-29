/**
* Name: Product
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Product

/* Insert your model definition here */

global {
	geometry shape <- square(1000);
}

species Product {
	rgb color <- #green;
	geometry shape <- circle(10);

	aspect default {
		draw shape color: color;
	}
}

experiment product_agent {
	init {
		create Product number: 10;
	}
	
	output {
		display product_agent {
			species Product;
		}
	}
}