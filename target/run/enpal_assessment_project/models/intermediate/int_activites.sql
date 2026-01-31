
  create view "postgres"."pipedrive_analytics"."int_activites__dbt_tmp"
    
    
  as (
    

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
                
          FROM "postgres"."pipedrive_analytics"."stg_activity" ac
          LEFT JOIN "postgres"."pipedrive_analytics"."stg_activity_types" act ON ac.type = act.type
          WHERE TRUE 
              AND ac.done
              AND act.name IN ('Sales Call 1', 'Sales Call 2')
)

SELECT *
FROM base
  );