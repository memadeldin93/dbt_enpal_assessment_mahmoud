{{ 
    config(
        materialized = 'view',
        tags = ['staging', 'pipedrive']
    ) 
}}

WITH 

transformed AS (
                    SELECT 
                            activity_id,
                            type,
                            assigned_to_user,
                            deal_id,
                            done,
                            CAST(due_to AS TIMESTAMP) AS due_to_dt,
                            ROW_NUMBER() OVER (PARTITION BY activity_id ORDER BY due_to) AS row_num 

                    FROM {{source('postgres_public', 'activity')}}
)

SELECT 
       activity_id,
       type,
       assigned_to_user,
       deal_id,
       done,
       due_to_dt
FROM transformed
WHERE row_num = 1