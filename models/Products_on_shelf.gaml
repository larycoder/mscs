/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Productsonshelf

/* Insert your model definition here */

global {
	init {
        file my_file <- csv_file("./includes/product.csv",',',string,true);
        write my_file.contents;
        create products from: my_file{
        	location <- any_location_in(world);
        }
    }
}

species products{
	int id;
	string name;
	string price_type;
	int price;
	int linked_id;
	aspect default{
		draw circle(5) color: #red;
	}
}
experiment test{
	output{
		display del{
			species products aspect: default;
		}
	}
}