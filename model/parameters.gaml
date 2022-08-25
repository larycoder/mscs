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
	
	
	
	// Global
	float time_for_a_day <- 20#s;//2 #mn;
	int end_of_game <- 30; //days
	int days <- 0;
	
	
	// People
	float product_scanning_range <- 5.0; //dist seeing the product
	float patienceTime <-  30#minute ;
	float rumor_threshold <-0.2;
	float converge <- rnd(0.0,1.0);
	float comeback_rate_threshold <-0.6 min: 0.6; // as first opinion is 0.8
	float _opinion <- 0 max:1.0;
	float _happiness <-0 max:1.0;
	
	
}