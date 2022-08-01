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
	
	// product order strategy weight
	float product_price_weight <- rnd(0.0,1.0) min: 0.0 max: 1.0;
	float nb_product_weight <- rnd(0.0, 1.0) min: 0.0 max: 1.0;
	float product_link_weight <- rnd(0.0, 1.0) min: 0.0 max: 1.0;
	float bias_weight <- rnd(0.0, 1.0) min: 0.0 max: 1.0;
	
	// product link present
	graph product_graph <- graph([]);
}

species product_type {
	geometry shape <- circle(0.2);
	rgb color <- #yellow;
	
	int id;
	string name;
	string price_type;
	int price;
	int linked_id; // deprecated
	list<product_type> my_links;
	
	// Eye-level > top-level > lower-level
	float height_chance <- 0.9; //default a random chance of buying
	
	// Height must in list [ "high", "eye", "low" ]
	string height;
	
	// Product arrangement strategy parameter
	float prod_price_percent;
	float nb_product_percent;
	float product_link_percent;
	float flip_percent <- 0.0;
	
	// basic params	
	action update_order_param_part_1 {
		prod_price_percent <- price / sum(product_type collect each.price);
		nb_product_percent <- length(product_type where(each.name = self.name)) / length(product_type);
	}
	
	// advance params
	action update_order_param_part_2 { // should be call after all products are created
		product_link_percent <- (prod_price_percent + sum(my_links collect each.prod_price_percent)) / (length(my_links) + 1);	
		flip_percent <- flip_percent + product_price_weight * prod_price_percent;
		flip_percent <- flip_percent + nb_product_weight * nb_product_percent;
		flip_percent <- flip_percent + product_link_weight * product_link_percent;
		flip_percent <- flip_percent + bias_weight;
		flip_percent <- flip_percent / 4;	
	}
	
	action update_height {
		if(flip(flip_percent)) {
			height <- "eye";
		} else if (flip(flip_percent)) {
			height <- "high";
		} else {
			height <- "low";
		}
	}

	aspect default {
		draw shape color: color;
	}
}

species product_link {
	aspect default {
		draw shape color: #orange;
	}
}

experiment product_agent {
	// TODO: add product link
	init {
		create product_type from: product_data_file {
			location <- any_location_in(world);
		}	
	}
	
	output {
		display product_agent {
			species product_type;
		}
	}
}