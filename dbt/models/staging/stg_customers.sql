-- Staging : on nettoie/renomme, 1 ligne = 1 client. Aucune logique métier ici.
with source as (
    select * from {{ source('raw', 'customers') }}
)

select
    cast(customer_id as integer) as customer_id,
    trim(name)                   as customer_name,
    upper(country)               as country_code,
    cast(signup_date as date)    as signup_date
from source
