/**
* Name: Modelutils14Opinion
* Based on the internal empty template. 
* Author: morpheus
* Tags: 
*/


model Modelutils14Opinion

/* Insert your model definition here */

/**
* Name: opinion
* Based on the internal empty template. 
* Author: morpheus
* Tags: 
*/


/* Insert your model definition here */

global torus: true{
	float converge <- rnd(0.0,1.0);
	int nb_init <- 5;
	float threshold <-0.2;	
	
	
	init {
	ask nb_init among people
		{
			color <- #red;
		}
		}
		
		
}

grid people width: 5 height: 5 neighbors:4 {
	float opinion <- rnd(0.0,1.0);
	
	reflex spread {
		ask one_of(neighbors){
			if(abs(myself.opinion-opinion) < threshold ){
				float temp <- opinion;
			opinion <- opinion + converge*(myself.opinion-opinion);
			myself.opinion <- myself.opinion + converge*abs(myself.opinion-temp);
			
			}
			
		}
	}
}




experiment e {
	output {
		
	display graph {
	chart "mon chart" type: series {
		
	loop ag over: people {
		data ag.name value: ag.opinion color: #blue;
}
}
	}
	
	}}




