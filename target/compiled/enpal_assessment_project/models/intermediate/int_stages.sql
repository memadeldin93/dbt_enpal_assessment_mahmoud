

WITH
users AS (
			SELECT 
				  deal_id,
				   new_value :: INT AS user_id,
				   change_dt AS assigned_user_start,
				   LEAD(change_dt) OVER(PARTITION BY deal_id,changed_field_key ORDER BY change_dt) AS assigned_user_end
			FROM "postgres"."pipedrive_analytics"."stg_deal_changes"
			WHERE TRUE 
				AND  changed_field_key= 'user_id'
) 
, 
base AS (
         SELECT 
                dc.deal_id,
                dc.change_dt,
                CAST(DATE_TRUNC('month', DATE(dc.change_dt)) AS DATE) AS month,
                dc.new_value :: INT AS stage_id,
                s.stage_name,
                s.funnel_step,
                u.user_id,
                u.assigned_user_start,
                u.assigned_user_end
                   
         FROM "postgres"."pipedrive_analytics"."stg_deal_changes" dc
         LEFT JOIN "postgres"."pipedrive_analytics"."stg_stages" s       ON dc.new_value = CAST(s.stage_id AS TEXT)
         LEFT JOIN users u                       ON dc.deal_id = u.deal_id 
					                                AND dc.change_dt >= u.assigned_user_start
					                                AND dc.change_dt <= COALESCE(assigned_user_end, CURRENT_DATE)
         WHERE TRUE 
            AND dc.changed_field_key= 'stage_id'
)

SELECT 
      *
FROM base