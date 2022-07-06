/**
* Name: Product
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Product

/* Insert your model definition here */

global {
	file product_data_file <- csv_file("../includes/product.csv", ",", string, true);
	geometry shape <- square(50);
}

species store_product {
	geometry shape <- circle(0.2);
	rgb color <- #yellow;
	
	int id;
	string name;
	string price_type;
	int price;
	int linked_id;

	aspect default {
		draw shape color: color;
	}
}

experiment product_agent {
	init {
		create store_product from: product_data_file {
			location <- any_location_in(world);
		}
	}
	
	output {
		display product_agent {
			species store_product;
		}
	}
}