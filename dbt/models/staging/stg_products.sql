-- Staging : catalogue produits. unit_price = prix de vente, cost_eur = coût d'achat.
with source as (
    select * from {{ source('raw', 'products') }}
)

select
    cast(product_id as integer) as product_id,
    cast(unit_price as decimal(10, 2)) as unit_price,
    cast(cost_eur as decimal(10, 2)) as cost_eur,
    trim(product_name) as product_name,
    lower(trim(category)) as category
from source
