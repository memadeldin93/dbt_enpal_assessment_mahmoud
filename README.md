# Pipedrive Funnel Case Study (dbt)

## Context & Goal
This project builds a reusable analytics foundation (not a one-off report) for analyzing a Pipedrive-like sales funnel using dbt. The evaluation focus areas are:

1. **Exploratory Analysis** - Investigate, analyze, and understand the data.
2. **Data Modeling** - Structure and organize data meaningfully for reuse.
3. **SQL Code Efficiency** - Optimize SQL for performance and maintainability.
4. **Project Organization & Clarity** - Make the project easy to understand, run, and extend.

The deliverable is a layered dbt model with documentation and tests so future KPIs can be implemented with minimal rework.

---

## Data Sources
- `postgres_public.activity`
- `postgres_public.activity_types`
- `postgres_public.deal_changes`
- `postgres_public.stages`
- `postgres_public.users`
- `postgres_public.fields` (field option normalization)

---

## 1) Exploratory Analysis (Data Investigation & Understanding)

### Duplicate discovery & data quality signals
I started by validating primary key assumptions and identifying duplicate patterns in the raw sources.

**Example checks:**
```sql
-- Duplicate activity_id in activity
SELECT activity_id, COUNT(*)
FROM public.activity
GROUP BY 1
HAVING COUNT(*) > 1;
```

```sql
-- Duplicate events in deal_changes at the "event grain"
WITH base AS (
  SELECT *
  FROM public.deal_changes dc
)
SELECT deal_id, change_time, changed_field_key, new_value, COUNT(*)
FROM base
GROUP BY 1,2,3,4
HAVING COUNT(*) > 1;
```

**Outcome / interpretation**
- Duplicates indicate the raw extracts do not fully align to an assumed "one row per natural key" grain.
- Deduplication and contract enforcement therefore belong in the **staging** layer (not downstream reporting), preventing inconsistencies across future KPIs.

### Data type corrections
A key example is standardizing `active` from string-like values into a **boolean**, reducing ambiguity and improving testability downstream (e.g., accepted values and filtering).

### Cross-source consistency checks
I checked overlap between activity events and deal stage changes. Only **two deals** were common between `deal_changes` and `activity`, and they did not follow the expected funnel ordering (with different users involved). This suggests either:
- the dataset is a slice (partial history), or
- extraction windows differ between sources.

Rather than forcing assumptions, I designed **anomaly flags** to surface inconsistencies without hiding them.

---

## 2) Data Modeling (Medallion / Layered Approach)
This project follows a medallion-style structure to keep models reusable and extensible.

### Staging layer (`stg_*`)
**Purpose:** Standardize sources into clean, typed, consistently named relations.
- Apply deduplication logic and enforce source contracts
- Rename and cast fields
- Create stable keys for joins
- Keep transformations minimal and explainable

### Intermediate layer (`int_*`)
**Purpose:** Apply business logic and construct reusable event streams.
- Build funnel timelines (stage changes + activities)
- Derive step/month bucketing
- Add window-based context (previous step/user)
- Add anomaly flags to detect unusual sequences (e.g., regressions or unexpected sub-step transitions)
- Create helper models such as month x step matrices for complete reporting spines

### Refined layer (`rep_*`)
**Purpose:** Publish curated, analytics-ready outputs with stable semantics and clear grain.
- Aggregate to reporting grains (e.g., monthly distinct deal counts by KPI/step)
- Join to spines (month x step) to guarantee complete outputs (including zeros)
- Exclude anomalous events where appropriate (while preserving anomaly visibility upstream)

This separation ensures future KPIs can be built by composing intermediate models rather than embedding business logic directly into reporting SQL.

---

## 3) SQL Code Efficiency (Performance & Scalability)

### Design choices that support efficiency
- **Filter early:** Apply `done = true` and KPI filters upstream where they become valid.
- **Avoid repeated heavy parsing:** JSON option expansion is isolated into a dedicated staging model for `fields` options.
- **Spine approach for completeness:** `int_step_month_matrix` provides a reusable "complete grid," preventing downstream queries from repeatedly generating missing month/step combinations.
- **Partitioning / clustering (where supported):** refined models are configured to partition by `month` and cluster by frequently filtered dimensions such as `kpi_name`.

### Practical considerations
- Window functions (`LAG`, `LEAD`) are used where temporal ordering is required. For large-scale datasets, deterministic tie-breakers (and/or event-type ordering) should be introduced if timestamps can collide.
- `SELECT *` is avoided in refined outputs to maintain stable contracts. Intermediate models can tolerate it early on, but explicit selects are recommended as the project matures.

---

## 4) Project Organization & Clarity

### Repository structure
- `models/staging/` -> `stg_*` source standardization
- `models/intermediate/` -> `int_*` business logic + reusable funnel event modeling
- `models/refined/` -> `rep_*` reporting-ready outputs
- `docs/` -> reusable docs blocks for models and columns
- `seeds/` -> business mappings (e.g., funnel steps) as version-controlled data assets
- `tests/` + schema tests -> contract enforcement at model and column level
- `macros/` -> shared logic where applicable

### Documentation strategy
Documentation is written as reusable `docs` blocks and referenced via `{{ doc('...') }}` so that:
- commonly reused fields have a single canonical definition
- each model documents grain, purpose, and key assumptions
- the DAG is navigable via `dbt docs`

### Testing strategy
- Generic tests (`not_null`, `unique`, `accepted_values`) enforce column-level contracts.
- `dbt_utils` is used for higher-level integrity checks (e.g., `unique_combination_of_columns`, expression-based assertions).
- Anomaly flags are not hidden; they are surfaced upstream and optionally excluded in refined reporting depending on the KPI definition.

---

## Key Models (High-level Flow)
- `stg_*`: typed and standardized sources (deduplication and naming conventions)
- `int_activities`: completed funnel activities enriched with funnel step metadata
- `int_stages`: stage change events enriched with stage metadata + assigned user at event time
- `int_stages_anmly`: anomaly signals for suspicious stage transitions
- `int_sales_funnel`: unified funnel event stream (activities + stages) with anomaly rules
- `funnel_steps` (seed): canonical funnel step mapping (decouples business logic from SQL)
- `int_step_month_matrix`: month x funnel step spine for consistent reporting
- `rep_sales_funnel_monthly`: monthly KPI table (distinct deals) excluding anomalies

---

## How to Run
```bash
dbt deps
dbt seed --select funnel_steps
dbt build
dbt docs generate
dbt docs serve
```

---

## Notable Assumptions & Trade-offs
- Stage progression should ideally use an explicit stage order rather than numeric comparisons on `stage_id`, since IDs can be arbitrary. Where ordering matters, a mapping/ordinal should be used.
- The dataset appears partially sliced across sources (limited overlap between deal changes and activities). Instead of forcing a narrative, anomaly flags preserve the signal and allow metric definitions to decide whether to exclude anomalies.

---

## Next Improvements (If This Were Production)
- Add deterministic ordering when multiple events share the same `change_dt`.
- Introduce a calendar spine for continuous month coverage (not only months present in the event table).
- Expand seed integrity tests (uniqueness, no missing steps, stable ordering).
- Add dbt exposures for key `rep_*` models to formalize downstream contracts.