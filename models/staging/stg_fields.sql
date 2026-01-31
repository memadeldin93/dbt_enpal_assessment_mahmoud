{{ 
    config(
        materialized = 'view',
        tags = ['staging', 'pipedrive']
    ) 
}}

WITH

raw AS (
        SELECT 
              id          AS field_id,
              field_key,
              name        AS field_name,
              field_value_options

        FROM {{source('postgres_public', 'fields')}}
)

, base AS (
            SELECT
                  field_id,
                  field_key,
                  field_value_options
                  
            FROM raw
            WHERE field_value_options IS NOT NULL
)

, exploded AS (
                SELECT
                      b.field_id,
                      b.field_key,
                      e.elem->>'id'    AS option_id,
                      e.elem->>'label' AS option_label

                FROM base b
                CROSS JOIN lateral
                    jsonb_array_elements(b.field_value_options) WITH ordinality AS e(elem, ord)
)

, transformed AS (
                    SELECT
                          r.field_id,
                          r.field_key,
                          r.field_name,
                          CASE
                              WHEN e.option_id ~ '^\d+$' THEN e.option_id::int
                              ELSE NULL
                          END AS option_id,
                          e.option_label
                        
                    FROM raw r
                    LEFT JOIN exploded e    USING (field_id)
)
SELECT
        *
FROM transformed
ORDER BY field_id, 
         option_id