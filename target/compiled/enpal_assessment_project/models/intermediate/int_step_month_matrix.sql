

WITH
all_unique_steps AS (
                        SELECT 
                               * 
                        FROM (
                                VALUES
                                    ('Lead Generation',              'Step 1'),
                                    ('Qualified lead',               'Step 2'),
                                    ('Sales Call 1',                 'Step 2.1'),
                                    ('Needs Assessment',             'Step 3'),
                                    ('Sales Call 2',                 'Step 3.1'),
                                    ('Proposal/Quote Preparation',   'Step 4'),
                                    ('Negotiation',                  'Step 5'),
                                    ('Closing',                      'Step 6'),
                                    ('Implementation/Onboarding',    'Step 7'),
                                    ('Follow-up/Customer Success',   'Step 8'),
                                    ('Renewal/Expansion',            'Step 9')
                             ) AS t (kpi_name, funnel_step)
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