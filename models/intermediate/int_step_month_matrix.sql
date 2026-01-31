{{ 
    config(
        materialized = 'view',
        tags = ['intermediate', 'pipedrive']
    ) 
}}

WITH
all_unique_steps AS (
                      SELECT
                          kpi_name,
                          funnel_step,
                          step_order
                      FROM {{ ref('funnel_steps') }}
)

, all_months AS (
                    SELECT DISTINCT month 
                    FROM {{ref("int_sales_funnel")}}
                )

, month_step_matrix AS (
                         SELECT
                               m.month,
                               s.kpi_name,
                               s.funnel_step
                         FROM all_months m
                         CROSS JOIN all_unique_steps s
                       )

SELECT *
FROM month_step_matrix