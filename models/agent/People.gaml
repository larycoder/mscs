/**
* Name: People
* Based on the internal empty template. 
* Author: group 2
* Tags: 
*/


model People

/* Insert your model definition here */

global {
	geometry shape <- square(1000);
}

species People {
	aspect default {
		draw circle(10) color: #blue;
	}
}

experiment people_agent {
	init {
		create People number: 10;
	}
	
	output {
		display people_agent {
			species People;	
		}
	}
}