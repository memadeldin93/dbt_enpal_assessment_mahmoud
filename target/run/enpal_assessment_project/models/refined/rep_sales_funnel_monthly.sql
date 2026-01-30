
  
    

  create  table "postgres"."pipedrive_analytics"."rep_sales_funnel_monthly__dbt_tmp"
  
  
    as
  
  (
    

WITH
monthly_data AS (
                    SELECT
                           month,
                           kpi_name,
                           funnel_step,
                           COUNT(DISTINCT deal_id) AS deals_count
                           
                    FROM "postgres"."pipedrive_analytics"."int_sales_funnel"
                    WHERE funnel_anmly_flg = 0
                    GROUP BY 
                             month, 
                             kpi_name, 
                             funnel_step
)

, final AS (
             SELECT
                    ms.month,
                    ms.kpi_name,
                    ms.funnel_step,
                    COALESCE(a.deals_count, 0) AS deals_count

             FROM "postgres"."pipedrive_analytics"."int_step_month_matrix" ms
             LEFT JOIN monthly_data a            ON ms.month = a.month
                                                    AND ms.kpi_name = a.kpi_name
                               
           )
SELECT *
FROM final
  );
  