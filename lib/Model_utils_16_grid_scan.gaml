/**
* Name: Modelutils16gridscan
* Based on the internal empty template. 
* Author: Son Ngoc Nguyen
* Tags: 
*/


model Modelutils16gridscan


/* Modeling of people getting product */

global{
    float max_range <- 5.0;
    int number_of_agents <- 10;
    
    init {
    	
    create my_species number: number_of_agents;
    
    create second_spec number: 50 {
    	color_code <- 0 ;
    }
    }
    
    reflex update {
    ask my_species {
        do wander amplitude: 180.0; 
//		if (not empty (my_grid.neighbors)) {
//			second_spec chosen_one <-one_of(second_spec inside my_grid.neighbors);
//		}
        
    }
  
    
//    ask second_spec {
//    	do update_color;
//    }
    ask my_grid {
        do update_color;
    } 
    }
}

species second_spec parent:spec_view{

	
 	int color_code <- 0;
	init {

		color <- color_code;
	}
	
	action update_color {
		color_code <- 0;
	}
	
	aspect default {
		if color_code = 0 {
			draw circle(1) color: #red ;
		} else if color_code = 1 {
			draw circle(1) color: #black ;
		}
		
	}
}

species my_species skills:[moving] parent:spec_view {
    float speed <- 2.0;
    init {
    	my_plot <- one_of(my_grid);
    }
    
    
    reflex update {
    	my_grid next_plot <- nil;
    	ask my_grid at_distance (5.0){
    		self.color_value <- 1;
	}
    }
    
    reflex move {
    	write my_plot.check ; 
    	
    	
    	if my_plot != nil{
    		if   (not empty (my_plot.neighbors)) {
    			
			list<second_spec> chosen_one ;
			ask my_grid at_distance (5.0){
				chosen_one <- second_spec where ( each.my_plot overlaps self );
				write " scanning  " + length(chosen_one);
				loop i over: chosen_one {
					i.color_code <-1;
				}
				
			}
			
			
//			chosen_one.color_code <- 1;
		}
    		
    	}
    	
	
    }
    
    
    aspect default {
    draw circle(1) color: #blue;
    }
}

species spec_view {
	my_grid my_plot;
//	string check <- "inherited ";
	
    reflex update {
    	my_grid next_plot <- nil;
    	ask my_grid at_distance (5.0){
		if self overlaps myself {
			next_plot <- self;
			myself.my_plot <- next_plot;
//			myself.my_plot.color_value <- 1;
			
		}
	}
    }
    
	
}


grid my_grid width:30 height:30 {
	string check <- "inherited ";
	int color_spec <-0;
	
    int color_value <- 0;
    second_spec spec ; 
    

    action update_color {
    if (color_value = 0) {
        color <- #green;
    } else if (color_value = 1) {
        color <- #yellow;
    } else if (color_value = 2) {
        color <- #red;
    }
    color_value <- 0;
    }
}

experiment MyExperiment type: gui {
    output {
        display MyDisplay type: java2D {
            grid my_grid lines: #black;
            species my_species aspect: default; 
            species second_spec aspect: default;
        }
    }
}