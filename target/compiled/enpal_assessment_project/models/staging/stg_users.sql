

with 

transformed as (

                SELECT 
                      id          as user_id,
                      name        as user_name,
                      email       as user_email,
                      modified    as user_modified_at

                FROM "postgres"."public"."users"
)

SELECT 
      *
FROM transformed