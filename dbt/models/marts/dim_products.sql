-- Mart : dimension produit + marge unitaire et ventes réalisées. Répond à "top produits / marge".
with products as (
    select * from {{ ref('stg_products') }}
),

sales as (
    select
        product_id,
        sum(quantity) as units_sold,
        sum(revenue_eur) as revenue_eur,
        sum(margin_eur) as margin_eur
    from {{ ref('int_orders_enriched') }}
    where status = 'completed'
    group by 1
)

select
    p.product_id,
    p.product_name,
    p.category,
    p.cost_eur,
    p.unit_price as price_eur,
    cast(p.unit_price - p.cost_eur as decimal(10, 2)) as unit_margin_eur,
    round((p.unit_price - p.cost_eur) / nullif(p.unit_price, 0) * 100, 1) as margin_pct,
    coalesce(s.units_sold, 0) as units_sold,
    coalesce(s.revenue_eur, 0) as revenue_eur,
    coalesce(s.margin_eur, 0) as margin_eur
from products as p
left join sales as s on p.product_id = s.product_id
