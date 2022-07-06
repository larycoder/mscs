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
    action activate_button{
		button b <- first(button overlapping #user_location);
		if b != nil{
			if b.btn_action = chosen_btn_action {
				chosen_btn_action <- "";
			}
			else {
				chosen_btn_action <- b.btn_action;
			}
		}
	} 
}

species button {
	rgb color;
	geometry shape <- square(200);
	string btn_action;
	
	aspect default {
		draw shape color: color;
		draw around(10.0,shape) color: #red;
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
		display game_section{
			
		}
	}
}