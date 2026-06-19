{% snapshot products_snapshot %}
{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='check',
        check_cols=['unit_price']
    )
}}
-- Snapshot SCD2 : capture l'état de products à CHAQUE run. Si unit_price change entre deux
-- runs, dbt ferme l'ancienne version (dbt_valid_to) et en ouvre une nouvelle (dbt_valid_from).
select
    cast(product_id as integer) as product_id,
    product_name,
    cast(unit_price as decimal(10, 2)) as unit_price
from {{ source('raw', 'products') }}
{% endsnapshot %}
