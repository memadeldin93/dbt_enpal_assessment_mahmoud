{{ 
    config(
        materialized = 'view',
        tags = ['intermediate', 'pipedrive']
    ) 
}}

WITH 
avtivities AS (
		   		SELECT 
				   	   deal_id,
					   name				AS kpi_name,
					   funnel_step,
					   assigned_to_user AS user_id,
					   due_to_dt		AS change_dt,
					   month,
					   0 				AS anmly_flg
		   		
				FROM {{ref("int_activites")}}
)
, stages AS (
			  SELECT 
			  		 deal_id,
			  		 stage_name			AS kpi_name,
					 funnel_step,
					 user_id,
					 change_dt,
					 month,
					 anmly_flg
			  FROM {{ref("int_stages_anmly")}}
)

,stg_funnel AS ( 
			    SELECT * FROM avtivities 
			    UNION ALL
			    SELECT * FROM stages
)

, int_funnel AS (
				  SELECT *,
						 LAG(funnel_step) OVER(PARTITION BY deal_id ORDER BY change_dt ASC) prev_step,
						 LAG(user_id)     OVER(PARTITION BY deal_id ORDER BY change_dt ASC) prev_user
						   
				  FROM stg_funnel
)

, final_funnel AS (
					SELECT *,
						   CASE 
						   		WHEN funnel_step= 'Step 2.1' AND COALESCE(prev_step, 'n') <> 'Step 2' AND user_id = prev_user THEN 1
						   		WHEN funnel_step= 'Step 3.1' AND COALESCE(prev_step, 'n') <> 'Step 3' AND user_id = prev_user THEN 1
								ELSE anmly_flg
						   END AS funnel_anmly_flg
					FROM int_funnel 
)

SELECT *
FROM final_funnel