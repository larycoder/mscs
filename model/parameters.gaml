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

	int cycle_per_day <- 100;
	
	// People
	int nb_people <- 2;
	int average_nb_friendPerPerson <- 3; //default 3
	float first_customers_rate <- 0.3 ; // 30% of population
	float daily_customers_rate <- 0.7; // 10% of population
	float product_scanning_range <- 5.0; //distance seeing the product
//	float patienceTime <-  30#minute ;
	float rumor_threshold <-0.1;
	float converge <- rnd(1,10);
	float comeback_rate_threshold <-0.6; // as first opinion is 0.8
	float comeback_for_fun_opinion_threshold <-0.7; // as first opinion is 0.8
	float _opinion <- 0.8  max:1.0; // init
	float _happiness <-0 max:1.0;
	float _happiness_impact_to_opinion <- 0.5; // default 0.5
	float high_price_happiness <- 0.5;
	float medium_price_happiness <- 1;
	float low_price_happiness <-1.3;
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
	
	
	
	// experiment output value
	 float round_revenue <- 0.0;
	 float round_shopping_nb <- 0.0;
	 int round_buying_nb <- 0;
	 float round_avg_hapiness <- 0.0;

}