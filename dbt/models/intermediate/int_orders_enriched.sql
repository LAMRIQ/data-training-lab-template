-- Intermediate : ligne de commande enrichie (client + produit) avec marge.
-- Grain = ligne de commande (order_id, product_id). La logique métier (marge) vit ICI une seule fois.
with items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

products as (
    select * from {{ ref('stg_products') }}
)

select
    -- clé de substitution stable de la ligne (md5 des clés naturelles)
    md5(cast(i.order_id as varchar) || '-' || cast(i.product_id as varchar)) as line_id,
    i.order_id,
    o.order_date,
    o.status,
    o.customer_id,
    i.product_id,
    p.product_name,
    p.category,
    i.quantity,
    cast(i.quantity * i.unit_price as decimal(10, 2)) as revenue_eur,
    cast(i.quantity * p.cost_eur as decimal(10, 2)) as cost_eur,
    cast(i.quantity * (i.unit_price - p.cost_eur) as decimal(10, 2)) as margin_eur
from items as i
inner join orders as o on i.order_id = o.order_id
inner join products as p on i.product_id = p.product_id
