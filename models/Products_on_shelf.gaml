/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model Productsonshelf

/* Insert your model definition here */

global {
    file my_file <- csv_file("./includes/product.csv",',',string,true);
    int daily <- 600#cycle;
    map stratergy_selection;
    bool end_of_round <- false;
    int round <- 0;
    int current_score <- 100;
    int total_shopping_people <- 1000;
    int total_buying_people <- 600;
    int total_revenue <- 330;
    int round_shopping_people <- 0;
    int round_buying_people <- 0;
    int round_revenue <- 0;
    float avg_happiness <- 100.0;
    bool ready <- false;
	init {
        create products from: my_file{
        	location <- any_location_in(world);
        }
        ready <- user_confirm("Situation",
        							"You are the new manager of this store,the last manager was fired because the revenue of the shop was too low and and the consequence is the shop almost being closed. As a manager, it is your job to maximize the income for the shop and make it great again.\nIn this game, your work to optimize the revenue is find a way to sort the product on the shelf in a proper way.");
		do quit_game(ready);
//		ready <- user_confirm("Notification","It's your first month, learn some job");
//		do quit_game(ready);
//        do create_button(#grey,{50.0,50.0});
//		do create_button(#darkblue,{50.0,80.0,0});
//		create button {
//			color <- #red;
//			location <- any_location_in(world.shape);
//		}
    }
//    action activate_button{
//		button b <- first(button overlapping #user_location);
//		if b != nil{
//			do die;
//		}
//	} 
//	action create_button (rgb c, geometry loc) {
//		create button {
//			color <- c;
//			location <- loc;
//		}
//	}
	action quit_game(bool ready){
		if (not ready){
			do die;
		}
	} 
	reflex set_end_of_round when: every(daily){
		end_of_round <- true;
	}
	reflex update_round when: end_of_round{
		if(round < 10){
			round <- round + 1;
			stratergy_selection <- user_input_dialog("Choose the strategy",[
					choose("High-level",string,"cheap", ["expensive","medium","cheap"]),
					choose("Eye-level",string,"expensive", ["expensive","medium","cheap"]),
					choose("Low-level",string,"medium", ["expensive","medium","cheap"])
				]);
			round_revenue <- round_revenue + 100;
			end_of_round <- false;
		}
		else {
			do pause;
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


experiment test type:gui{
	output{
		display main_stage refresh: end_of_round{
			
			graphics "Stats"{
				draw "Round: "+round+"/10" at: {10,10} color: #green;
				draw "High-level: "+ string(stratergy_selection at "High-level") at: {20,20} color: #red;
				draw "Eye-level: "+ string(stratergy_selection at "Eye-level") at: {20,25} color: #red;
				draw "Low-level: "+ string(stratergy_selection at "Low-level") at: {20,30} color: #red;
				
//				draw "Current round status" at: {0,140} color: #red;
//				draw "Came client: "+ tround_shopping_people at: {20,160} color: #red;
//				draw "Served client: "+ round_buying_people at: {20,170} color: #red;
//				draw "Revenue: "+ round_revenue at: {20,180} color: #red;
				
				draw "Score: "+ current_score at: {70,10} color: #black;
			}
		}
		display "Total status"{
			chart "Total status" type:histogram 
									x_label:''
			 						y_label:'' {
					data "Total came client" value: total_shopping_people color:#blue;
					data "Total served client" value: total_buying_people color:#yellow;
					data "Total revenue" value: total_revenue/1000 color:#grey;
				}
		}
		display "Round status" refresh:every(daily){
			chart "Past information" type:series
									x_label:''
			 						y_label:'' {
					data "Total came client" value: round_shopping_people  color:#blue;
					data "Total served client" value: round_buying_people color:#yellow; 
					data "Total revenue" value: round_revenue/1000 color:#grey;
				}
		}
		display "Happiness"{
			chart "Avarage happiness" type:series{
				data "Avg. Happiness" value: avg_happiness color:#darkgrey;
			}
		}
	}
}