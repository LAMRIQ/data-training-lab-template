-- Intermediate : agrégat par client sur les commandes complétées (base des métriques client).
-- On agrège les LIGNES (revenue/marge) puis on compte les commandes distinctes.
with lines as (
    select * from {{ ref('int_orders_enriched') }}
    where status = 'completed'
)

select
    customer_id,
    count(distinct order_id) as nb_orders,
    sum(revenue_eur) as lifetime_value_eur,
    sum(margin_eur) as total_margin_eur,
    min(order_date) as first_order_date,
    max(order_date) as last_order_date
from lines
group by 1
