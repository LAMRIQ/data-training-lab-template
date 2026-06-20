-- Intermediate : reconstruit l'historique de prix en SCD2 (valid_from / valid_to) à partir
-- de product_price_history, par lead(). C'est la forme qu'un snapshot dbt matérialise.
with history as (
    select
        cast(product_id as integer) as product_id,
        cast(valid_from as date) as valid_from,
        cast(unit_price as decimal(10, 2)) as unit_price
    from {{ source('raw', 'product_price_history') }}
)

select
    product_id,
    valid_from,
    unit_price,
    lead(valid_from) over (
        partition by product_id
        order by valid_from
    ) as valid_to,
    lead(valid_from) over (
        partition by product_id
        order by valid_from
    ) is null as is_current
from history
