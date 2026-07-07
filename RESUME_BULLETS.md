# Resume bullets — Project 1 (Olist / dbt / Snowflake)

XYZ format, result first. Two kinds of claims here: **repo facts** (safe to use
now — verifiable from the code) and **[MEASURE]** slots you must fill from your
own Snowflake runs before using. Never ship a bullet with a bracket in it.

## Ready now (grounded in the repo)

- Built a production-grade analytics platform on 100k-order Brazilian
  e-commerce data by modeling 9 raw sources into a Kimball star schema
  (4 dimensions, order-grain fact, 3 analysis marts) with dbt Core on
  Snowflake, enforced by 26 source-level data tests.

- Eliminated cross-PR interference in analytics CI by designing a GitHub
  Actions pipeline that builds every run into an ephemeral schema
  (`CI_<run_id>`) and gates merges on dbt source tests, parse, and compile.

- Preserved order-lifecycle history the source system overwrites by
  implementing an SCD2 dbt snapshot on order status, enabling
  time-in-status analysis.

- Prevented silent metric corruption in rolling-window revenue reporting by
  designing an incremental dbt model with a 30-day reprocessing window and
  `on_schema_change='fail'` contracts.

## Fill, then use

- Cut mart refresh runtime by [MEASURE: X%] ([MEASURE: full-refresh s] →
  [MEASURE: incremental s]) by converting the daily-revenue mart to an
  incremental materialization with a trailing-window merge strategy.

- Kept monthly warehouse spend under $[MEASURE] by right-sizing to an X-Small
  warehouse with 60s auto-suspend and restricting CI to parse/compile/source
  tests instead of full builds.

- Surfaced and documented [MEASURE: N] data-quality defects in the raw feed
  (non-unique review IDs, untranslated categories, missing delivery
  timestamps), converting each into either a dbt test or a documented
  modeling decision.

## Interview follow-ups these bullets invite (be ready)

Why order grain instead of item grain? Why is CI not running full builds, and
what's the state-based alternative? Why omit the unique test on review_id?
What breaks if the incremental lookback window is shorter than the rolling
window? All answered in DECISIONS.md — read it before the interview, twice.
