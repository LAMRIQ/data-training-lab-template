-- Mart : métriques par client (cohorte, LTV, marge, segment). Répond à "rétention & valeur client".
with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select * from {{ ref('int_customer_orders') }}
)

select
    c.customer_id,
    c.customer_name,
    c.country_code,
    c.signup_date,
    cast(date_trunc('month', c.signup_date) as date) as cohort_month,
    co.first_order_date,
    co.last_order_date,
    coalesce(co.nb_orders, 0) as nb_orders,
    coalesce(co.lifetime_value_eur, 0) as lifetime_value_eur,
    coalesce(co.total_margin_eur, 0) as total_margin_eur,
    case
        when coalesce(co.nb_orders, 0) = 0 then 'sans_achat'
        when co.lifetime_value_eur >= 2800 then 'vip'
        when co.lifetime_value_eur >= 1600 then 'regulier'
        else 'occasionnel'
    end as segment
from customers as c
left join customer_orders as co on c.customer_id = co.customer_id
