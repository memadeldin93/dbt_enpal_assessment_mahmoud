{{ 
    config(
        materialized = 'view',
        tags = ['intermediate', 'pipedrive']
    ) 
}}

WITH 
base AS (
          SELECT 
                ac.activity_id,
                ac.deal_id,
                ac.type,
                act.name,
                act.funnel_step,
                ac.assigned_to_user,
                ac.due_to_dt,
                CAST(DATE_TRUNC('month', DATE(ac.due_to_dt)) AS DATE) AS month
                
          FROM {{ref("stg_activity")}} ac
          LEFT JOIN {{ref("stg_activity_types")}} act ON ac.type = act.type
          WHERE TRUE 
              AND ac.done
              AND act.name IN ('Sales Call 1', 'Sales Call 2')
)

SELECT *
FROM base