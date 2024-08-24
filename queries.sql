--общее количество покупателей из таблицы customers.
SELECT Count(customer_id) AS customers_count
FROM   customers;

--10-ка лучших продавцов
SELECT     Concat(employees.first_name, ' ', employees.last_name) AS seller,
           Count(sales.sales_id)                                  AS operations,
           Floor(Sum(products.price * sales.quantity))            AS income
FROM       sales
INNER JOIN employees
ON         sales.sales_person_id = employees.employee_id
INNER JOIN products
ON         sales.product_id = products.product_id
GROUP BY   seller
ORDER BY   income DESC limit 10;

--продавцы, чья средняя выручка меньше средней выручки по всем продавцам.
SELECT     Concat(employees.first_name, ' ', employees.last_name) AS seller,
           Floor(Avg(products.price * sales.quantity))            AS average_income
FROM       sales
INNER JOIN employees
ON         sales.sales_person_id = employees.employee_id
INNER JOIN products
ON         sales.product_id = products.product_id
GROUP BY   seller
HAVING     Avg(products.price * sales.quantity) <
           (
                      SELECT     Avg(products.price * sales.quantity)
                      FROM       sales
                      INNER JOIN employees
                      ON         sales.sales_person_id = employees.employee_id
                      INNER JOIN products
                      ON         sales.product_id = products.product_id )
ORDER BY   average_income;

--Данный запрос содержит информацию о выручке по дням недели.
WITH tab AS
(
           SELECT     (first_name
                                 || ' '
                                 || last_name)       AS seller,
                      Floor(Sum(quantity * price))   AS income,
                      To_char(sale_date, 'Day')      AS day_of_week,
                      Extract(isodow FROM sale_date) AS dow
           FROM       employees                      AS e
           INNER JOIN sales                          AS s
           ON         e.employee_id = s.sales_person_id
           LEFT JOIN  products AS p
           ON         s.product_id = p.product_id
           GROUP BY   (first_name
                                 || ' '
                                 || last_name),
                      To_char(sale_date, 'Day'),
                      Extract(isodow FROM sale_date) )
SELECT   seller,
         Lower(day_of_week) AS day_of_week,
         Round(income)      AS income
FROM     tab
ORDER BY dow,
         seller;

--Кол-во покупателей в разных возрастных группах: 16-25, 26-40 и 40+.
WITH tab AS
(
       SELECT
              CASE
                     WHEN age BETWEEN 16 AND    25 THEN '16-25'
                     WHEN age BETWEEN 26 AND    40 THEN '26-40'
                     WHEN age > 40 THEN '40+'
              END AS age_category
       FROM   customers )
SELECT   age_category,
         Count(age_category) AS age_count
FROM     tab
GROUP BY age_category
ORDER BY age_category;

--Данные по количеству уникальных покупателей и выручке, которую они принесли.
WITH tab AS
(
          SELECT    customer_id,
                    To_char(sale_date, 'YYYY-MM') AS selling_month,
                    Sum(quantity * price)         AS income
          FROM      employees
          LEFT JOIN sales AS s
          ON        employee_id = s.sales_person_id
          LEFT JOIN products AS p
          ON        s.product_id = p.product_id
          WHERE     To_char(sale_date, 'YYYY-MM') IS NOT NULL
          GROUP BY  To_char(sale_date, 'YYYY-MM'),
                    customer_id )
SELECT   selling_month,
         Count(customer_id) AS total_customers,
         Floor(Sum(income)) AS income
FROM     tab
GROUP BY selling_month
ORDER BY selling_month;

--Данные о покупателях, первая покупка которых была в ходе проведения акций.
WITH tab AS
(
          SELECT    (c.first_name
                              || ' '
                              || c.last_name) AS customer,
                    Min(sale_date)            AS sale_date,
                    Sum(price * quantity)
          FROM      customers AS c
          LEFT JOIN sales     AS s
          ON        c.customer_id = s.customer_id
          LEFT JOIN products AS p
          ON        s.product_id = p.product_id
          GROUP BY  (c.first_name
                              || ' '
                              || c.last_name)
          HAVING    Sum(price * quantity) = 0 ), tab2 AS
(
          SELECT    (c.first_name
                              || ' '
                              || c.last_name) AS customer,
                    Min(sale_date)            AS sale_date,
                    (e.first_name
                              || ' '
                              || e.last_name) AS seller
          FROM      sales                     AS s
          LEFT JOIN customers                 AS c
          ON        s.customer_id = c.customer_id
          LEFT JOIN employees AS e
          ON        s.sales_person_id = e.employee_id
          GROUP BY  (c.first_name
                              || ' '
                              || c.last_name),
                    (e.first_name
                              || ' '
                              || e.last_name) )
SELECT     tab.customer,
           tab.sale_date,
           seller
FROM       tab
INNER JOIN tab2
ON         tab.customer = tab2.customer
AND        tab.sale_date = tab2.sale_date
GROUP BY   tab.customer,
           tab.sale_date,
           seller
ORDER BY   customer;
