{{ 
    config(
        materialized = 'view',
        tags = ['staging', 'pipedrive']
    ) 
}}

WITH 

transformed AS (
                    SELECT 
                            deal_id,
                            CAST(change_time AS TIMESTAMP) change_dt,
                            changed_field_key,
                            new_value,
                            row_number() OVER (
                                PARTITION BY deal_id, changed_field_key, new_value,  change_time) AS rn

                    FROM {{source('postgres_public', 'deal_changes')}}
)

SELECT 
      deal_id,
      change_dt,
      changed_field_key,
      new_value

FROM transformed
WHERE rn = 1