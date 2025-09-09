
-- \dt  
-- \d orders  
-- \d accounts  
-- \d sales_reps  
-- \d region 


-- 1: order IDs where gloss_qty OR poster_qty > 4000

SELECT 
    id  
FROM orders 
WHERE 
    gloss_qty > 4000        
    OR poster_qty > 4000    
ORDER BY id;  


-- 2: Orders with zero standard_qty AND (gloss_qty OR poster_qty) > 1000
SELECT 
    id,
    standard_qty,     
    gloss_qty,       
    poster_qty,       
    total_amt_usd  
FROM orders 
WHERE 
    standard_qty = 0                   
    AND (
        gloss_qty > 1000              
        OR poster_qty > 1000          
    )
ORDER BY total_amt_usd DESC; 


--  3: company names starting with C or W

SELECT 
    name AS company_name,
    primary_poc AS primary_contact
FROM accounts 
WHERE 
    (
        name LIKE 'C%'              
        OR name LIKE 'W%'            
    )
    AND (
        primary_poc LIKE '%ana%'    
        OR primary_poc LIKE '%Ana%' 
    )
    AND primary_poc NOT LIKE '%eana%'   
ORDER BY name;         


-- 4: Region, Sales rep, and account

SELECT 
    r.name AS region_name,              
    sr.name AS sales_rep_name,         
    a.name AS account_name           
FROM region r
    INNER JOIN sales_reps sr            
        ON r.id = sr.region_id
    INNER JOIN accounts a              
        ON sr.id = a.sales_rep_id
ORDER BY a.name; 