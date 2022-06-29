/**
* Name: Model1
* Based on the internal empty template. 
* Author: hieplnc
* Tags: 
*/


model Model1

import "../agent/People.gaml"
import "../agent/Shelf.gaml"
import "../agent/Product.gaml"

/* Insert your model definition here */

global {
	// number of agents
	int nb_shelf <- 10;
	int nb_people <- 10;
	int nb_product <- 10;
	
	init {
		create Shelf number: nb_shelf {
			deg <- one_of([0.0, 90.0]);
			loop while: length((Shelf - self) where(each overlaps self)) > 0 {
				location <- any_location_in(world.shape);
			}
		}
	}
}

experiment simple_product_shelf {
	output {
		display simple_product_shelf {
			species Shelf;
		}
	}
}