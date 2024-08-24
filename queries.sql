--общее количество покупателей из таблицы customers.
SELECT COUNT(customer_id) AS customers_count
FROM customers;

--10-ка лучших продавцов
select
    concat(employees.first_name, ' ', employees.last_name) as seller,
    count(sales.sales_id) as operations,
    floor(sum(products.price * sales.quantity)) as income
from sales
inner join employees on sales.sales_person_id = employees.employee_id
inner join products on sales.product_id = products.product_id
group by seller
order by income desc
limit 10;

--продавцы, чья средняя выручка меньше средней выручки по всем продавцам.
select
    concat(employees.first_name, ' ', employees.last_name) as seller,
    floor(avg(products.price * sales.quantity)) as average_income
from sales
inner join employees on sales.sales_person_id = employees.employee_id
inner join products on sales.product_id = products.product_id
group by seller
having
    avg(products.price * sales.quantity)
    < (
        select avg(products.price * sales.quantity)
        from sales
        inner join employees on sales.sales_person_id = employees.employee_id
        inner join products on sales.product_id = products.product_id
    )
order by average_income;

--Данный запрос содержит информацию о выручке по дням недели.
with tab as (
    select
        (first_name || ' ' || last_name) as seller,
        FLOOR(SUM(quantity * price)) as income,
        TO_CHAR(sale_date, 'Day') as day_of_week,
        EXTRACT(isodow from sale_date) as dow
    from employees as e
    inner join sales as s on e.employee_id = s.sales_person_id
    left join products as p on s.product_id = p.product_id
    group by
        (first_name || ' ' || last_name),
        TO_CHAR(sale_date, 'Day'),
        EXTRACT(isodow from sale_date)
)

select
    seller,
    LOWER(day_of_week) as day_of_week,
    ROUND(income) as income
from tab
order by dow, seller;

--Кол-во покупателей в разных возрастных группах: 16-25, 26-40 и 40+.
with tab as (
    select
        case
            when age between 16 and 25 then '16-25'
            when age between 26 and 40 then '26-40'
            when age > 40 then '40+'
        end as age_category
    from customers
)

select
    age_category,
    count(age_category) as age_count
from tab
group by age_category
order by age_category;

--Данные по количеству уникальных покупателей и выручке, которую они принесли.
with tab as (
    select
        customer_id,
        to_char(sale_date, 'YYYY-MM') as selling_month,
        sum(quantity * price) as income
    from employees
    left join sales as s on employee_id = s.sales_person_id
    left join products as p on s.product_id = p.product_id
    where to_char(sale_date, 'YYYY-MM') is not null
    group by to_char(sale_date, 'YYYY-MM'), customer_id
)

select
    selling_month,
    count(customer_id) as total_customers,
    floor(sum(income)) as income
from tab
group by selling_month
order by selling_month;

--Данные о покупателях, первая покупка которых была в ходе проведения акций.
with tab as (
    select
        (c.first_name || ' ' || c.last_name) as customer,
        min(sale_date) as sale_date,
        sum(price * quantity)
    from customers as c
    left join sales as s on c.customer_id = s.customer_id
    left join products as p on s.product_id = p.product_id
    group by (c.first_name || ' ' || c.last_name)
    having sum(price * quantity) = 0
),

tab2 as (
    select
        (c.first_name || ' ' || c.last_name) as customer,
        min(sale_date) as sale_date,
        (e.first_name || ' ' || e.last_name) as seller
    from sales as s
    left join customers as c on s.customer_id = c.customer_id
    left join employees as e on s.sales_person_id = e.employee_id
    group by
        (c.first_name || ' ' || c.last_name),
        (e.first_name || ' ' || e.last_name)
)

select
    tab.customer,
    tab.sale_date,
    seller
from tab
inner join tab2
    on
        tab.customer = tab2.customer
        and tab.sale_date = tab2.sale_date
group by tab.customer, tab.sale_date, seller
order by customer;