/**
* Name: snip
* Based on the internal empty template. 
* Author: admin
* Tags: 
*/


model snip

/* Insert your model definition here */

global{

//	geometry wall <- envelope(polygon([{3,5}, {4,5},{5,5}]));
}

grid cell width: 10 height: 10 neighbors: 4 {
    init {
        write "my column index is:" + grid_x;
        write "my row index is:" + grid_y;
         
    }
}
species bug {
    int size <- rnd(10);
    geometry wall <- envelope(polygon([{3,5}, {4,5},{5,5}]));
      aspect circle {
          draw circle(2) color: #blue;
      }
}


experiment check type: gui{
	
}