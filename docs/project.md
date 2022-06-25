# Alternate Subject 3: Products on a shelf
Depending on the placement of products on a shelf, people tend to buy them more or less often.
Products at the eye level are prefered. Thus as a shop owner you have an incentive to place
the more expensive products at the eye level to maximize your revenues. But as a shopper, you
prefer stores that have the product that you came in to buy placed at that level. So if a shop
owner places only the most expensive products at the eye-level he will see the number of its
customers decrease as they will end up choosing other stores. There is also a second dynamic
in place: some products are linked, and if a customer decides to buy one, he will certainly
buy the linked product too, wherever it is on the shelf. The probability of people buying
products at the eye-level is the highest, then comes the top-level and finally the lower-level.
But buying products from the top-level makes people less happy than buying from the lower-level
which itself makes people less happy than if they bought from the eye-level.

## Step 1
Model that dynamic, and the evolution of the shop’s revenues, number of clients and
general happiness of the customers. You could create a finite number of products that
have a type (rice, lighter, sheet of paper…) , a price (you can have multiple products
for the same price) and possibly a linked type to represent that some products are often
bought together (for example sheet of paper could be linked to pen). Then place those
objects randomly on a grid representing the shelf and see what happens. For the people
they come to the shop one after the other with a random type of product they want to buy
and given fixed probabilities and its presence or not in the shelf will buy it or not,
once out of the shop they calculate their happiness based on the fact that they found
or not what they wanted and how easy it was to get.

## Step 2
Define different strategies of filling the shelf. Should you dynamically change the
type of product every time one is bought on the shelf ? Should you always keep the
same layout ? Should you put all the expensive ones at eye-level ? SHould you
concentrate on one type of product and ignore the others ? etc… Then use the batch
to explore those strategies and analyze the results
## Step 3

Turn it into an interactive simulation, you could pick yourself the shelf layout
and see how it evolves


## Referent

Alexis Drogoul, alexis.drogoul@ird.fr
Baptiste Lesquoy, baptistelesquoy@protonmail.com
Lucas Grosjean  lucas.grosjean@edu.univ-fcomte.fr
Patrick Taillandier patrick.taillandier@inrae.fr
Arthur Brugière arthur.brugiere@ird.fr



