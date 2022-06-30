/**
* Name: Product
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Product

/* Insert your model definition here */

global {
	geometry shape <- square(50);
}

species store_product {
	geometry shape <- circle(0.2);
	rgb color <- #green;

	int category;
	int price;

	aspect default {
		draw shape color: color;
	}
}

experiment product_agent {
	init {
		create store_product number: 10;
	}
	
	output {
		display product_agent {
			species store_product;
		}
	}
}