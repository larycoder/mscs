/**
* Name: Model1
* Based on the internal empty template. 
* Author: hieplnc
* Tags: 
*/


model Model1

/* Insert your model definition here */

global{
    float max_range <- 5.0;
    int number_of_agents <- 10;
    init {
    create my_species number: number_of_agents;
    create second_spec number: 10 {
    	color_code <- 0 ;
    	ask one_of(my_grid) {
    		myself.location <- self.location;
    		self.spec <- myself;
    	}
    }
    
    
    }
    
    reflex update {
    ask my_species {
        do wander amplitude: 180.0; 
        
//        specs_ <- (self neighbors_at (max_range));
//        write "specs " + length (specs_) ; 

//		if (not empty (my_grid.neighbors)) {
//			second_spec chosen_one <-one_of(second_spec inside my_grid.neighbors);
//		}

        ask my_grid  at_distance(max_range) {
        
		    
        
        if(self overlaps myself) {
        	
            self.color_value <- 2;
            self.grid_value <-1;
            
//            if self.spec != nil{
//            	self.spec.color_code <- #black;
//            
//            ask self.spec{
//            	do update_color;
//            }
//            
//            write "self.spec.color_code " + self.spec.color_code;
//            }
            
//            ask second_spec {
//		    	if(self overlaps myself) {
//		    		
//		        self.color_code <- #black;
//		    }
//		    
//		    }
        } 
        else if (self.color_value != 2) {
            self.color_value <- 1;
            self.color_spec <- 1 ;
//            self.color_spec  <- #yellow;
        }
        
        }
    }
  
    
    ask second_spec {
    	do update_color;
    }
    ask my_grid {
        do update_color;
    }   
    }
}

species second_spec {
//	my_grid cell;
	
 	int color_code <- 0;
	init {
//		location <- one_of(my_grid).location;	
		color <- color_code;
	}
	
	action update_color {
		
		
		
		ask my_grid[int(location[0]), int(location[1]) ]  {
			
			write "Heree " + self.color_spec;
			myself.color_code <- self.color_spec;
			
//			if(self overlaps myself)  {
////				myself.color_code<- self.color_spec;
//				self.color_value <- 0;
//				
//				if self.grid_value =1 {
//					write "self.grid_value " + self.grid_value;
//					myself.color_code <- #blue;
//				}
//			} else if myself.color_code != #blue {
//				myself.color_code <- #yellow;
//			}
//			color <- myself.color_code;
		}
		
		
	}
	aspect default {
		if color_code = 0 {
			draw circle(1) color: #red ;
		} else if color_code = 1 {
			draw circle(1) color: #black ;
		}
		
	}
}

species my_species skills:[moving] {
    float speed <- 2.0;
//    list<second_spec> specs_ ; 
    aspect default {
    draw circle(1) color: #blue;
    }
}

grid my_grid width:30 height:30 {
	
	int color_spec <-0;
	
    int color_value <- 0;
    second_spec spec ; 
    
//    reflex check  {
//    	ask second_spec at_distance 5 {
//    		myself.color_value <- 2;
//    	}
//    }
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