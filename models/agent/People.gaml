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
	rgb color <- #blue;
	geometry shape <- circle(10);

	aspect default {
		draw shape color: color;
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