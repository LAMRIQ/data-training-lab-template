-- Staging : en-tête de commande. 1 ligne = 1 commande (le détail produit vit dans stg_order_items).
with source as (
    select * from {{ source('raw', 'orders') }}
)

select
    cast(order_id as integer) as order_id,
    cast(customer_id as integer) as customer_id,
    cast(order_date as date) as order_date,
    cast(amount_eur as decimal(10, 2)) as amount_eur,
    lower(trim(status)) as status,
    cast(updated_at as timestamp) as updated_at
from source
