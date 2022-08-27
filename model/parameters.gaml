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
	int cycle_per_day <- 600;
	
	// People
	int nb_people <- 10;
	float first_customers_rate <- 0.5 ; // 30% of population
	float daily_customers_rate <- 0.1; // 10% of population
	float product_scanning_range <- 5.0; //distance seeing the product
	float patienceTime <-  30#minute ;
	float rumor_threshold <-0.2;
	float converge <- rnd(0.0,1.0);
	float comeback_rate_threshold <-0.6 min: 0.6; // as first opinion is 0.8
	float comeback_for_fun_opinion_threshold <-0.7 min: 0.7; // as first opinion is 0.8
	float _opinion <- 0.8  max:1.0; // init
	float _happiness <-0 max:1.0;
	float high_price_happiness <- 0.95;
	float medium_price_happiness <- 1;
	float low_price_happiness <-1.1;
	int _expensive_tolerance <-3;
	// People:Constants
	
	string SHOPPING <-"SHOPPPING";
	string COUNTER <- "COUNTER"; // maynot need
	string DOOROUT <- "DOOROUT"; // maynot need
	string DOORIN <- "DOORIN";
	string DONE <- "DONE";
	
	// Product:Constants
	string HIGH_RATE <- 0.6;
	string EYE_RATE <- 0.9;
	string LOW_RATE <- 0.3;
	
	
}