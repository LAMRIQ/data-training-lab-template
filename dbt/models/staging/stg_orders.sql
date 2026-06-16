-- Staging : typage + renommage des commandes. 1 ligne = 1 commande.
with source as (
    select * from {{ source('raw', 'orders') }}
)

select
    cast(order_id as integer)      as order_id,
    cast(customer_id as integer)   as customer_id,
    cast(order_date as date)       as order_date,
    cast(amount_eur as decimal(10,2)) as amount_eur,
    lower(status)                  as status
from source
