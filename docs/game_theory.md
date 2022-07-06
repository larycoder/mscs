# Project

## Shelf Agents [Priority: High]:
    - Shape

## People Agents:
    - Come time
    - Height
    - Moving skill
    - Buy rate:
        - Parameter or random
        - Depent on price (maybe)
    - Satisfaction status
        - Formula -> abs(target - eye-level) * buy_rate
        - If (Satisfaction status) > threshold : comeback and persuade **friendship group to come**
    - Buying rules:
        - Target (products to buy)
        - Price of the product
        - Linked buy rate -> buy random products in the list

## Product Agents: (pre-define) [Priority: High]
    - Position on shelf (Location -> Height, which shelf it located)
    - quantities (reduce when some one buy)
    - Import price
    - Sell price
    - Linked_products (create friendship to list of other product)

## World Agent [Priority: High]: (Aim to reconstruct a shop which contain people agents, shelf agents and product agents)
    - Tax -- could avoid (already count import price)
    - Vacation: In vacation the buy_rate or the more people come to the shop
    - In gate, checkout gate

## Global rule (Monitor) [Priority: Medium]:
    - Shop owner has initial money
    - After each cycle (month), the profit will add to the initial money
    - Cost : buy product + marketing price + customer care price + staff's salary (over one cycle)
    - Revenues : all price of sold products (over one cycle)
    - Profit: Revenues - Cost (over one cycle)
    - List of sold products on each category over one cycle (Cost, Revenues, Profit, Nb_of_sold)

## Shop owner
    - Action [Priority: Low]:
        - Chose product to buy each cycle
        - Marketing
        - Customer Care

    - Strategy [Priority: Low]:
        - SaleOff:
            - Time
            - Category
            - Products
        - Change open, close time
        - Increase marketing system
        - Increase customer care system
        - Increase the staff quality
        - Chose height of each product and price

## Game rule:
    - Each cycle will be 1 minute, one round is one day (from 8AM to 10PM).
    - After each day the player can reconstruct the products by new stratery and continue the next round.
    - Their are about 15-20 products construct by csv with different price, some will link to eachother
    - If the happiness > 80%, they will invite thier friend in friend to the shop

    - If the happiness < 20%, they will ask thier friend to not come to the shop

    - Choose the stratergy [param]
        - Choose [expensive, average, cheap] to the [high, eye, low] level
        - Ramdomly place product
    - Client have random_of_max_money or inf_money so their happiness depent on that when they saw the product on the shelf [param]
        - The clients only buy when they see the product <= their money, and most close to them, if there are 2 same product (which sastisfy the price), take the closet
        - If the clients run out of patien time, they will leave and decrease the happiness [param]
        - If the cients buy the product, increase the happiness [param]
        - The happiness are more when the clients buy the product Eye-level > lower-level > top-level [param]
        - The buy_rate is increase by follow Eye-level > top-level > lower-level [param]

## Game simulation
    - Game event (random more number of ppl to the shop)
    - Each month show the number of customer served + total sell product + profit
    - Scoring method: number of customer + total sell product + profit
