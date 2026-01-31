
  create view "postgres"."pipedrive_analytics"."int_step_month_matrix__dbt_tmp"
    
    
  as (
    

WITH
all_unique_steps AS (
                      SELECT
                          kpi_name,
                          funnel_step,
                          step_order
                      FROM "postgres"."pipedrive_analytics"."funnel_steps"
)

, all_months AS (
                    SELECT DISTINCT month 
                    FROM "postgres"."pipedrive_analytics"."int_sales_funnel"
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
  );