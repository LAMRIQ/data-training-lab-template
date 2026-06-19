-- Test SINGULIER : la somme des lignes d'une commande doit retomber au centime sur amount_eur.
-- Un test dbt = un SELECT qui doit renvoyer 0 ligne. S'il en renvoie, une commande ne réconcilie pas.
with items as (
    select order_id, sum(quantity * unit_price) as total
    from {{ ref('stg_order_items') }}
    group by 1
)

select
    o.order_id,
    o.amount_eur,
    i.total
from {{ ref('stg_orders') }} as o
inner join items as i on o.order_id = i.order_id
where round(o.amount_eur, 2) <> round(i.total, 2)
