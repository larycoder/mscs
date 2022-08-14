/**
* Name: Reputation
* Based on the internal empty template. 
* Author: admin
* Tags: 
*/


model Reputation

/* Insert your model definition here */

import "../Model_.gaml"




species friendship_link parallel: true{
	
	aspect default {
		draw shape color: #blue;
	}
}


species socialLinkRepresentation{
	people origin;
//	agent destination;
	float recommendation;
	rgb my_color;
	
	aspect base{
		draw line([origin,recommendation],50.0) color: my_color;
	}
}