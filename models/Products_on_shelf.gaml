/**
* Name: Productsonshelf
* Based on the internal empty template. 
* Author: Son Ngoc Nguyen
* Tags: 
*/


model Productsonshelf

import "model/Model_1.gaml"

/* Insert your model definition here */

experiment my_chart {
	parameter "product_price_weight" var: product_price_weight step: 0.1;
	parameter "nb_product_weight" var: nb_product_weight step: 0.1;
	parameter "product_link_weight" var: product_link_weight step: 0.1;
	parameter "bias_weight" var: bias_weight step: 0.1;

	output {
		display "product_order_revenue" {
			chart "product_order_to_revenue" type: xy {	
				data "product_price" value: { product_price_weight, total_revenue } color: #red;
				data "nb_product" value: { nb_product_weight, total_revenue } color: #green;
				data "product_link" value: { product_link_weight, total_revenue } color: #pink;
				data "bias" value: { bias_weight, total_revenue } color: #brown;

			}
		}
	}
}

experiment output_on_time {
	parameter "product_price_weight" var: product_price_weight step: 0.1;
	parameter "nb_product_weight" var: nb_product_weight step: 0.1;
	parameter "product_link_weight" var: product_link_weight step: 0.1;
	parameter "bias_weight" var: bias_weight step: 0.1;

	output {
		display "product_order_revenue" {
			chart "output_on_time" type: series {
				data "revenue" value: total_revenue / 1000 color: #red;
				data "shopping_people" value: total_shopping_people color: #brown;
				data "buying_people" value: total_buying_people color: #green;

			}
		}
	}
}