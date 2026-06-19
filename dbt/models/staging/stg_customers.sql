-- Staging : 1 ligne = 1 client. On caste/renomme/normalise, aucune logique métier ici.
with source as (
    select * from {{ source('raw', 'customers') }}
)

select
    cast(customer_id as integer) as customer_id,
    trim(customer_name) as customer_name,
    upper(trim(country_code)) as country_code,
    cast(signup_date as date) as signup_date
from source
