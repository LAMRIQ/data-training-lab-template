-- Mart : table de faits des ventes (1 ligne = 1 commande complétée), prête pour la BI.
with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
)

select
    o.order_id,
    o.order_date,
    o.customer_id,
    c.country_code,
    o.amount_eur,
    o.status
from orders o
inner join customers c using (customer_id)
where o.status = 'completed'
