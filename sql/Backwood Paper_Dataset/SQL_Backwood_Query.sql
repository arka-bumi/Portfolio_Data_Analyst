/* “I know that the price/standard_qty paper varies from one order to the next.
I would like this ratio across all of the sales made.” */

SELECT
  SUM(standard_amt_usd) / SUM(standard_qty) AS avg_price_per_standard_paper
FROM `backwoodpaper_sql_tutorial.orders`
WHERE standard_qty > 0
