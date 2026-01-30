

WITH 

transformed AS (
                 SELECT 
                         id   AS activity_type_id,
                         name,
                         type,
                         CASE 
                       		 WHEN name= 'Sales Call 1' THEN 'Step 2.1'
                       		 WHEN name= 'Sales Call 2' THEN 'Step 3.1'
                  	     END 				AS funnel_step,
                         CASE WHEN active= 'Yes' THEN TRUE ELSE FALSE END AS is_active
                            
                  FROM "postgres"."public"."activity_types"
)

SELECT *
FROM transformed