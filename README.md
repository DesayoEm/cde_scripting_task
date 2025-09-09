# Posey  Analysis Solutions

## Question 1: Order IDs with high gloss or poster quantities

```sql
-- Find order IDs where gloss_qty OR poster_qty > 4000
SELECT id 
FROM orders 
WHERE gloss_qty > 4000 OR poster_qty > 4000
ORDER BY id;
```

## Question 2: Specialized orders (zero standard, high premium)

```sql
-- Orders with zero standard_qty AND (gloss_qty OR poster_qty) > 1000
SELECT id, standard_qty, gloss_qty, poster_qty, total_amt_usd
FROM orders 
WHERE standard_qty = 0 
  AND (gloss_qty > 1000 OR poster_qty > 1000)
ORDER BY total_amt_usd DESC;
```

## Question 3: Company names with specific criteria

```sql
-- Companies starting with 'C' or 'W' with contacts containing 'ana' but not 'eana'
SELECT name AS company_name, primary_poc AS primary_contact
FROM accounts 
WHERE (name LIKE 'C%' OR name LIKE 'W%')
  AND (primary_poc LIKE '%ana%' OR primary_poc LIKE '%Ana%')
  AND primary_poc NOT LIKE '%eana%'
ORDER BY name;
```

## Question 4: Sales territory mapping

```sql
-- Region, sales rep, and account relationships
SELECT 
    r.name AS region_name,
    sr.name AS sales_rep_name,
    a.name AS account_name
FROM region r
    INNER JOIN sales_reps sr ON r.id = sr.region_id
    INNER JOIN accounts a ON sr.id = a.sales_rep_id
ORDER BY a.name;
```

## To Run

```bash
# Connect to database
psql -h localhost -U postgres -d posey
```
