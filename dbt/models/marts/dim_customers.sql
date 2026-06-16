-- Mart : dimension client enrichie (1 ligne = 1 client + métriques agrégées).
with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
    where status = 'completed'
),

customer_orders as (
    select
        customer_id,
        count(*)            as nb_orders,
        sum(amount_eur)     as lifetime_value_eur,
        min(order_date)     as first_order_date
    from orders
    group by 1
)

select
    c.customer_id,
    c.customer_name,
    c.country_code,
    c.signup_date,
    coalesce(co.nb_orders, 0)          as nb_orders,
    coalesce(co.lifetime_value_eur, 0) as lifetime_value_eur,
    co.first_order_date
from customers c
left join customer_orders co using (customer_id)
