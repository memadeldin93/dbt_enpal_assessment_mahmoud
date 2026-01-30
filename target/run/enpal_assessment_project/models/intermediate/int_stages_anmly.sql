
  create view "postgres"."pipedrive_analytics"."int_stages_anmly__dbt_tmp"
    
    
  as (
    

WITH 
stages AS (
			SELECT 
				  *,
				  LAG(stage_id) OVER(PARTITION BY deal_id ORDER BY change_dt ASC) prev_step,
				  LAG(user_id)  OVER(PARTITION BY deal_id ORDER BY change_dt ASC) prev_user,
				  ROW_NUMBER()  OVER(PARTITION BY deal_id ORDER BY change_dt ASC) rn
				  
			FROM "postgres"."pipedrive_analytics"."int_stages" 			
)

, stages_anmly AS (
					SELECT 
						   *,
						   CASE WHEN stage_id <= prev_step AND user_id = prev_user  THEN 1 ELSE 0 END AS anmly_flg
								
					FROM stages
)

SELECT *
FROM stages_anmly
  );