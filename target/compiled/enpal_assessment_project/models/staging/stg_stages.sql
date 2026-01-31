

WITH 

transformed AS (
                    SELECT 
                            stage_id,
                            stage_name,
                            CASE 
	                            WHEN stage_name= 'Lead Generation'              THEN 'Step 1'
	                            WHEN stage_name= 'Qualified lead'               THEN 'Step 2'
	                            WHEN stage_name= 'Needs Assessment'             THEN 'Step 3'
	                            WHEN stage_name= 'Proposal/Quote Preparation'   THEN 'Step 4'
	                            WHEN stage_name= 'Negotiation'                  THEN 'Step 5'
	                            WHEN stage_name= 'Closing'                      THEN 'Step 6'
	                            WHEN stage_name= 'Implementation/Onboarding'    THEN 'Step 7'
	                            WHEN stage_name= 'Follow-up/Customer Success'   THEN 'Step 8'
	                            WHEN stage_name= 'Renewal/Expansion'            THEN 'Step 9'
                            END AS funnel_step

                    FROM "postgres"."public"."stages"
)

SELECT *
FROM transformed