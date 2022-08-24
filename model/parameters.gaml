/**
* Name: parameters
* Based on the internal empty template. 
* Author: admin
* Tags: 
*/

@no_experiment
model parameters

/* Insert your model definition here */


global{
	float time_for_a_day <- 20#s;//2 #mn;
	int end_of_game <- 30; //days
	int days <- 0;
	float product_scanning_range <- 5.0; //dist seeing the product
	
	// experiment output value
	 float round_revenue <- 0.0;
	 float round_shopping_nb <- 0.0;
	 float round_buying_nb <- 0.0;
	 float round_avg_hapiness <- 0.0;
}