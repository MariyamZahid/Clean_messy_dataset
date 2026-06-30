# this is a dummy dataset where price is not same for the product or quantity, good for data cleaning

# create ecommerce table

create table if not exists ecommerce_sales
(ID	int,
 Customer_Name	varchar(50) not Null,
Order_ID	varchar(50) null,
Order_Date	varchar(50) null,
Product	varchar(50) null,
 Category	varchar(50) null,
Quantity varchar(50) null,
Price	varchar(50) null,
Payment_Method	varchar(50) null,
Status	varchar(50) null,
Total	varchar(50) null);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/messy_ecommerce_sales_data.csv'
into table ecommerce_sales
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

# checking whether customer name is assign correctly or not
select ID, customer_Name,
substring_index(customer_name, '_', -1) as id from ecommerce_sales
where ID <> substring_index(customer_name, '_', -1);

# updating date 
update ecommerce_sales
set order_date = case 
when order_date like '%/%' then str_to_date(order_date, '%m/%d/%Y')
when order_date regexp '^[A-Za-z]{3} [0-9]{1,2} [0-9]{4}$' then str_to_date(order_date, '%b %e %Y')
else NULL
end;

# updating category in proper format (first letter capital rest small), then updating category column as Home, Electronics, Sports, Books, and Clothing
update ecommerce_sales
set category = concat(upper(left(category,1)),lower(substring(category,2,length(category))));

update ecommerce_sales
set category = case when product in ('Blender','Lamp', 'Microwave', 'Vacuum')  then 'Home'
when product in ('Headphones','Laptop', 'Smartphone', 'Smartwatch') then 'Electronics'
when product in ('Basketball','Football', 'Tennis Racket', 'Yoga Mat') then 'Sports'
when product in ('Biography','Comics', 'Fiction', 'Science') then 'Books'
when product in ('Jacket','Jeans', 'Shoes', 'T-shirt') then 'Clothing'
end;

# updating quantity (removing letter, - sign from the quantity, replacing 0 with null)
update ecommerce_sales
set quantity = case when quantity regexp '^[0-9]{1}[A-Za-z]$' then abs(left(quantity, 1))
when quantity = 0 then null
else abs(quantity) end;

# updating price (replacing number names with number, $, replacing 0 with null)
update ecommerce_sales
set price = case when price = 'four hundred' then '400'
when price regexp '^[A-Za-z]+$' then null
when price = '0' then null
else abs(replace(price,'$',''))
end;

# update total (replacing 0 with null, correcting total by multiplying price with quantity)
update ecommerce_sales
set total = case when total = 0 then null else abs(total) end; 


update ecommerce_sales
set total = case when quantity is not null or price is not null then round((quantity * price), 2) end;


# dropping id no 196 as both quantity and price are null
delete from ecommerce_sales
where id = 196;


# removing duplicates
# 1. creating temporary table with rwno. partition by id
# 2. delete rownumber 2
# 3. update the main table
# 4. deleting the temporary table

create temporary table ecommerce_sales2
(select *,
row_number() over (partition by id) as rwno
from ecommerce_sales);

delete from ecommerce_sales2
where rwno = 2;

delete from ecommerce_sales;

insert into ecommerce_sales
(select id,
customer_name,
order_id,
order_date,
product,
category,
quantity,
price,
payment_method,
status,
total
from ecommerce_sales2);

drop temporary table ecommerce_sales2;

# checking whether null quantity or price can be replaced with avg

with avg_quan as
(select *,
round(avg(quantity) over(partition by product, quantity),2) as avg_quantity,
round(avg(price) over(partition by product, quantity), 2 ) as avg_price
from ecommerce_sales)
select *, 
round(avg_quantity*avg_price, 2) as avg_total 
from avg_quan
where product = 'Comics' and quantity = 5;

# checking if quantity or price can be updated from the other col
# after checking, following conclusion is made
# - for a single product price differs due to this null value cannot be replaced

select product,
category,
quantity,
payment_method,
status,
count(*) as cnt
from ecommerce_sales
group by product,
category,
quantity,
payment_method,
status
order by cnt desc, product asc, quantity asc;

select * from ecommerce_sales
where product in ('Fiction', 'Science') and status in ('Returned', 'Processing') and Payment_Method in ('Cash on Delivery', 'Paypal') and quantity in (2, 5)
order by product, quantity;

# removing columns where quantity or price is null

delete from ecommerce_sales
where total is null;

delete from ecommerce_sales
where price = 0;

# modifying data type of all cols
alter table ecommerce_sales
modify column order_date date,
modify column quantity int,
modify column price int,
modify column total int
;

# price col show outlier for product like blender, shoes, laptop

select product, min(price) as min_price,
max(price) as max_price from ecommerce_sales
group by product
order by min_price;

