-- Mart : ventes complétées agrégées par jour (grain = order_date). Répond à "CA et tendance".
with lines as (
    select * from {{ ref('int_orders_enriched') }}
    where status = 'completed'
),

daily as (
    select
        order_date,
        count(distinct order_id) as nb_orders,
        sum(quantity) as nb_items,
        sum(revenue_eur) as revenue_eur,
        sum(margin_eur) as margin_eur
    from lines
    group by 1
)

select
    order_date,
    nb_orders,
    nb_items,
    revenue_eur,
    margin_eur,
    cast(revenue_eur / nullif(nb_orders, 0) as decimal(10, 2)) as avg_order_value_eur
from daily
