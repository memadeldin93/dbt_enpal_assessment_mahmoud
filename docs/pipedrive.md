{% docs stg_activity_types %}
# stg_activity_types
Staging model that standardizes the Pipedrive `activity_types` source.
Each record represents a distinct activity type (e.g., call, meeting, email)
as defined in the Pipedrive CRM tool. This model cleans and renames columns
to support downstream activity and funnel analysis.
{% enddocs %}

{% docs activity_type_id %}
Unique identifier for the activity type in Pipedrive.
{% enddocs %}

{% docs activity__name %}
Human-readable name of the activity type (e.g., Sales Call 1, Follow Up Call,...).
{% enddocs %}

{% docs activity__type %}
Classification of the activity, such as 'call' or 'meeting'.
This helps link activities to specific funnel steps like Sales Call 1 or Sales Call 2.
{% enddocs %}

{% docs activity__active %}
A flag indicating whether the activity type is active in the current Pipedrive configuration.
{% enddocs %}


{% docs stg_activity %}
# stg_activity

Staging model that standardizes the Pipedrive `activity` source data.
Each record represents a logged or scheduled activity (e.g., call, meeting)
linked to a deal and user. This model renames fields, enforces correct datatypes,
and prepares activity data for downstream funnel tracking.

{% enddocs %}

{% docs stg_activity__activity_id %}
Identifier for each activity record in Pipedrive.
{% enddocs %}

{% docs stg_activity__assigned_to_user %}
Identifier of the user (sales rep) assigned to the activity.
{% enddocs %}

{% docs stg_activity__deal_id %}
Foreign key referencing the related deal to which the activity belongs.
{% enddocs %}

{% docs stg_activity__done %}
Boolean flag indicating whether the activity has been completed (true)
or is still scheduled (false).
{% enddocs %}

{% docs stg_activity__due_to_dt %}
Timestamp indicating when the activity is due or occurred.
{% enddocs %}


{% docs stg_deal_changes %}
# stg_deal_changes

Staging model that standardizes the Pipedrive `deal_changes` source data.
Each record represents a change made to a deal’s field within Pipedrive,
including stage transitions and other updates. This model renames and casts
key columns to proper data types for use in downstream deal funnel analysis.

{% enddocs %}

{% docs deal_id %}
Identifier for the deal affected by the change.
{% enddocs %}

{% docs change_dt %}
Timestamp indicating when the change occurred.
{% enddocs %}

{% docs changed_field_key %}
The field name that was modified (e.g., 'stage_id', 'user_id'). Used to identify
which kind of change occurred within the deal history.
{% enddocs %}

{% docs change_new_value %}
The new value that the field was updated to after the change. When `changed_field_key = 'stage_id'`,
this represents the stage the deal was moved into.
{% enddocs %}

{% docs stg_fields_options %}
# stg_fields_options

Staging model that extracts and normalizes **field value options** from the Pipedrive `fields` source.

This model:
- selects field metadata (`field_id`, `field_key`, `field_name`)
- explodes `field_value_options` (a JSON array) into one row per option
- casts numeric option ids to integers when possible

Output grain: **one row per (field_id, option_id)**, plus a single row per field when no options exist (option columns null).

{% enddocs %}

{% docs field_id %}
Identifier of the field from the upstream `fields` source.
{% enddocs %}

{% docs field_key %}
Stable key used by the source system to reference the field (useful for mapping business logic).
{% enddocs %}

{% docs field_name %}
Human-readable display name of the field.
{% enddocs %}

{% docs option_id %}
Option identifier extracted from `field_value_options`.

Casted to integer when the option id is purely numeric; otherwise null.
{% enddocs %}

{% docs option_label %}
Human-readable label for the option value.
{% enddocs %}

{% docs stg_stages %}
# stg_stages

Staging model that standardizes the Pipedrive `stages` source data.
Each record represents a stage in the sales pipeline within Pipedrive CRM.

{% enddocs %}

{% docs stage_id %}
Identifier for the pipeline stage in Pipedrive.
{% enddocs %}

{% docs stage_name %}
Descriptive name of the stage (e.g., 'Qualified lead', 'Negotiation', 'Closing').
{% enddocs %}

{% docs stages__funnel_step %}
map the stage name to a desired funnel step (e.g. step1, step2)
{% enddocs %}

{% docs stg_users %}
# stg_users

Staging model that standardizes the Pipedrive `users` source.

Each record represents a single user (e.g., sales rep, admin) from the upstream system.
This model renames columns and prepares user attributes for downstream ownership, attribution,
and activity/deal analysis.

{% enddocs %}

{% docs stg_users__user_id %}
Unique identifier for the user in the upstream `users` source.
{% enddocs %}

{% docs stg_users__user_name %}
Full name of the user as stored in the upstream system.
{% enddocs %}

{% docs stg_users__user_email %}
Email address of the user.
{% enddocs %}

{% docs stg_users__user_modified_at %}
Timestamp of the most recent modification to the user record in the upstream system.
{% enddocs %}

{% docs int_activities %}
# int_activities

Intermediate model that filters and enriches completed Pipedrive activities for funnel analysis.

Logic:
- uses `stg_activity` as the base activity set
- joins `stg_activity_types` to enrich activities with the activity type name and funnel step
- keeps only completed activities (`done = true`)
- filters to the funnel call activities: `Sales Call 1`, `Sales Call 2`
- adds `month` derived from `due_to_dt` truncated to month

**Grain:** one row per `activity_id` for qualifying sales call activities.

{% enddocs %}

{% docs int_activities__month %}
Month bucket derived from `due_to_dt` (month start date).
Used for monthly aggregation.
{% enddocs %}

{% docs int_stages %}
# int_stages

Intermediate model that creates a stage-change history for each deal and enriches it with:
- stage metadata (stage name and funnel step)
- the user assigned to the deal at the time of the stage change (based on deal change history)

Logic:
- extracts user assignment periods from `stg_deal_changes` where `changed_field_key = 'user_id'`
- selects stage change events from `stg_deal_changes` where `changed_field_key = 'stage_id'`
- joins stage metadata from `stg_stages`
- attaches the assigned user whose assignment window covers the stage change timestamp

**Grain:** one row per `(deal_id, change_dt)` stage-change event.

{% enddocs %}

{% docs int_stages__month %}
Month bucket derived from `change_dt` (month start date).
Used for monthly aggregation.
{% enddocs %}

{% docs int_stages__user_id %}
User identifier assigned to the deal during the stage change event window.
Derived from `stg_deal_changes` where `changed_field_key = 'user_id'`.
{% enddocs %}

{% docs int_stages__assigned_user_start %}
Timestamp when the user assignment started for the deal (from the `user_id` change event time).
{% enddocs %}

{% docs int_stages__assigned_user_end %}
Timestamp when the user assignment ended for the deal (next `user_id` change event time).
Null means the assignment is currently active (end is treated as current date in joins).
{% enddocs %}

{% docs int_stages_anmly %}
# int_stages_anmly

Intermediate model that augments `int_stages` with anomaly-detection features for stage transitions.

Adds:
- `prev_step`: previous stage for the same deal (by `change_dt`)
- `prev_user`: previous assigned user for the same deal (by `change_dt`)
- `rn`: sequence number of the stage change within the deal
- `anmly_flg`: anomaly flag where the stage appears to move backwards or not progress
  while the assigned user has not changed

Anomaly logic:
- `anmly_flg = 1` when `stage_id <= prev_step` **and** `user_id = prev_user`
- otherwise `anmly_flg = 0`

**Grain:** one row per `(deal_id, change_dt)` stage-change event (same as `int_stages`).

{% enddocs %}

{% docs int_stages_anmly__prev_step %}
Previous `stage_id` for the same `deal_id`, ordered by `change_dt`.
Null for the first stage-change event of each deal.
{% enddocs %}

{% docs int_stages_anmly__prev_user %}
Previous `user_id` for the same `deal_id`, ordered by `change_dt`.
Null for the first stage-change event of each deal.
{% enddocs %}

{% docs int_stages_anmly__rn %}
Row number of the stage-change event within a deal, ordered by `change_dt` (starting at 1).
{% enddocs %}

{% docs int_stages_anmly__anmly_flg %}
Anomaly flag:
- `1` when `stage_id <= prev_step` and the assigned `user_id` did not change (`user_id = prev_user`)
- `0` otherwise
{% enddocs %}

{% docs int_sales_funnel %}
# int_sales_funnel

Intermediate model that builds a unified **sales funnel event stream** per deal by combining:
- completed funnel activities (e.g., Sales Call 1 / Sales Call 2)
- stage change events (deal moved between pipeline stages)

The model unions both event sources into a single timeline and adds:
- `prev_step`, `prev_user`: previous funnel step and user within the deal timeline
- `funnel_anmly_flg`: anomaly flag that applies additional funnel-specific rules on top of `anmly_flg`

Notes:
- `kpi_name` represents the event label (activity name or stage name).
- `change_dt` is treated as the event timestamp for ordering within each deal.

**Grain:** one row per funnel event per deal (activity or stage event).

{% enddocs %}

{% docs int_sales_funnel__kpi_name %}
Event label used for funnel reporting:
- activity name for activity events
- stage name for stage events
{% enddocs %}

{% docs int_sales_funnel__anmly_flg %}
Base anomaly flag carried from the stage anomaly model (or set to 0 for activity events).
Values: 0 (normal), 1 (anomalous).
{% enddocs %}

{% docs int_sales_funnel__prev_step %}
Previous `funnel_step` for the same `deal_id`, ordered by `change_dt`.
Null for the first event of each deal.
{% enddocs %}

{% docs int_sales_funnel__prev_user %}
Previous `user_id` for the same `deal_id`, ordered by `change_dt`.
Null for the first event of each deal.
{% enddocs %}

{% docs int_sales_funnel__funnel_anmly_flg %}
Final anomaly flag after applying funnel-specific rules.

Rules applied:
- flags certain sub-steps (e.g. Step 2.1, Step 3.1) as anomalies when the prior step is not the expected parent step
  and the assigned user did not change.
- otherwise uses the base `anmly_flg`.

Values: 0 (normal), 1 (anomalous).
{% enddocs %}

{% docs int_step_month_matrix %}
# int_step_month_matrix

Intermediate model that creates a complete **month × funnel step** matrix for reporting.

It:
- defines a fixed set of funnel steps (`kpi_name`, `funnel_step`) via an inline VALUES list
- collects all distinct months present in `int_sales_funnel`
- cross joins months to steps to ensure every month contains every funnel step (even if no events occurred)

Use cases:
- consistent time-series reporting (avoids missing rows)
- building KPI tables and funnel heatmaps by month

**Grain:** one row per `(month, funnel_step)`.

{% enddocs %}

{% docs int_step_month_matrix__kpi_name %}
Funnel KPI label (human-readable), representing either a stage name or activity name in the funnel.
{% enddocs %}

{% docs int_step_month_matrix__funnel_step %}
Canonical funnel step identifier (e.g., Step 1, Step 2, Step 2.1).
{% enddocs %}

{% docs rep_sales_funnel_monthly %}
# rep_sales_funnel_monthly

Refined reporting model that produces a **monthly sales funnel KPI table**.

It:
- counts distinct deals per month and KPI (`kpi_name`, `funnel_step`) from `int_sales_funnel`
- excludes anomalous events (`funnel_anmly_flg = 0`)
- left joins onto `int_step_month_matrix` so that every month contains every funnel step
- fills missing combinations with `deals_count = 0`

**Grain:** one row per `(month, kpi_name, funnel_step)`.

{% enddocs %}

{% docs rep_sales_funnel_monthly__deals_count %}
Number of distinct deals that reached the KPI (`kpi_name`, `funnel_step`) in the given month,
excluding anomalies (`funnel_anmly_flg = 0`).
{% enddocs %}

