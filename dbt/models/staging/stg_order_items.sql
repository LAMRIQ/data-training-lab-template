-- Staging : lignes de commande. 1 ligne = 1 produit d'une commande (le grain fin).
with source as (
    select * from {{ source('raw', 'order_items') }}
)

select
    cast(order_id as integer) as order_id,
    cast(product_id as integer) as product_id,
    cast(quantity as integer) as quantity,
    cast(unit_price as decimal(10, 2)) as unit_price
from source
