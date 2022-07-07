/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Productsonshelf

/* Insert your model definition here */

global {
	string ACTION_HOME <- "home" const: true;
	string ACTION_WORK <- "work" const: true;
	string ACTION_KILL <- "kill" const: true;
	string ACTION_ADD_LIST <- "add_list" const: true;
	string ACTION_CREATE_ALL_BUILDING <- "create_all_building" const: true;
	string ACTION_KILL_ALL_HOUSE <- "kill_all_house" const:true;
	string ACTION_KILL_ALL_WORK_PLACE <- "kill_all_work_place" const:true;
	string ACTION_KILL_ALL_BUILDING <- "kill_all_bulding" const:true;
    file my_file <- csv_file("./includes/product.csv",',',string,true);
	init {
        create products from: my_file{
        	location <- any_location_in(world);
        }
        do create_button(#grey,ACTION_HOME,{400.0,200.0});
		do create_button(#darkblue,ACTION_WORK,{400.0,600.0});
    }
    action activate_button{
//		button b <- first(button overlapping #user_location);
//		if b != nil{
//			do die;
//		}
	} 
	action create_button (rgb color, string btn_action, geometry loc) {
		create button {
			color <- color;
			btn_action <- btn_action;
			location <- loc;
		}
	}
}

species button {
	rgb color;
	geometry shape <- square(20);
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
experiment test type:gui{
	output{
		display user_panel{
			species button;
//			event mouse_down action: activate_button;
		}
		display del{
			species products aspect: default;
		}
	}
}