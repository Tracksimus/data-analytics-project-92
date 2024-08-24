--Данный запрос считает общее количество покупателей из таблицы customers, колонку назвал customers_count
SELECT COUNT(customer_id) AS customers_count
FROM customers;

--Данный запрос выводит 10-ку лучших продавцов, показывая их имя и фамилию, суммарную выручку с проданных товаров и количество проведенных сделок. Жанные отсортированны по убыванию выручки, избавившись от чисел после запятой, т.е. они округленны в меньшую сторону.
select 
concat(employees.first_name, ' ', employees.last_name) as seller,
count(sales.sales_id) as operations,
floor(SUM(products.price * sales.quantity)) as income
from sales
inner join employees on sales.sales_person_id = employees.employee_id 
inner join products on sales.product_id = products.product_id 
group by seller
order by income desc 
limit 10;

--Данный запрос выводит информацию о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам. Таблица отсортирована по выручке по возрастанию. Представлены имя и фамилия продавца, средняя выручка продавца за сделку с округлением до целого в меньшую сторону.
select 
concat(employees.first_name, ' ',employees.last_name) as seller,
floor(AVG(products.price * sales.quantity)) as average_income
from sales
inner join employees on sales.sales_person_id = employees.employee_id 
inner join products on sales.product_id = products.product_id 
group by seller
having AVG(products.price * sales.quantity) < 
(select
AVG(products.price * sales.quantity)
from sales
inner join employees on sales.sales_person_id = employees.employee_id 
inner join products on sales.product_id = products.product_id)
order by average_income;

--Данный запрос содержит информацию о выручке по дням недели. Каждая запись содержит имя и фамилию продавца, название дня недели на английском языке и суммарную выручку продавца в определенный день недели, округленную до целого числа в меньшую сторону. Данные отсортированы по порядковому номеру дня недели и продавцу.
with tab as (select
    (first_name||' '||last_name) as seller, 
       FLOOR(sum(quantity*price)) as income, 
       to_char(sale_date, 'Day') as day_of_week,
        extract(isodow from sale_date) as dow
    from employees e
    inner join sales s on e.employee_id = s.sales_person_id  
    left join products p on s.product_id = p.product_id
    group by (first_name||' '||last_name), to_char(sale_date, 'Day'), extract(isodow from sale_date))
    select seller, lower(day_of_week) as day_of_week, round(income) as income
    from tab
    order by dow, seller;

--Данный запрос показывает количество покупателей в разных возрастных группах: 16-25, 26-40 и 40+. Итоговая таблица отсортирована по возрастным группам.
with tab as(select case when age between 16 and 25 then '16-25'
     when age between 26 and 40 then '26-40'
     when age > 40 then '40+' end as age_category 
     from customers)
     select 
     age_category, 
     count(age_category) as age_count
     from tab
     group by age_category
     order by age_category;

--Данный запрос показывает данные по количеству уникальных покупателей и выручке, которую они принесли. Данные сгруппированы по дате, которая представлена в числовом виде ГОД-МЕСЯЦ. Итоговая таблица отсортирована по дате по возрастанию.
with tab as (
   select to_char(sale_date, 'YYYY-MM') as selling_month,
          customer_id,
          sum(quantity*price) as income
  from  employees 
  left join sales as s on employee_id = s.sales_person_id  
  left join products as p on s.product_id = p.product_id
  where to_char(sale_date, 'YYYY-MM') is not null
  group by  to_char(sale_date, 'YYYY-MM'), customer_id
    )
    select selling_month, 
                    count(customer_id) as total_customers,
                    floor(sum(income)) as income
    from tab
    group by selling_month
    order by selling_month;

--Данный запрос показывает данные о покупателях, первая покупка которых была в ходе проведения акций (акционные товары отпускали со стоимостью равной 0). Итоговая таблица отсортирована по id покупателя. Таблица содержит поля "имя и фамилия покупателя", "дата покупки", "имя и фамилия продавца".
with tab as
    (
    select (c.first_name||' '||c.last_name) as customer, 
    min(sale_date) as sale_date, 
    sum(price*quantity)
    from customers c 
    left join sales s on c.customer_id = s.customer_id
    left join products p on s.product_id = p.product_id
    group by (c.first_name||' '||c.last_name)
    having sum(price*quantity) = 0
    ), 
    
    tab2 as 
    (
   select (c.first_name||' '||c.last_name) as customer, min(sale_date) as sale_date, 
    (e.first_name||' '|| e.last_name) as seller
    from sales s
    left join customers c on s.customer_id = c.customer_id
    left join employees e  on e.employee_id = s.sales_person_id
    group by (c.first_name||' '||c.last_name), (e.first_name||' '|| e.last_name)
    )
    select tab.customer, tab.sale_date, seller
    from tab
    inner join tab2 on tab.customer = tab2.customer 
    and tab.sale_date = tab2.sale_date
    group by tab.customer, tab.sale_date, seller
    order by customer;