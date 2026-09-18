> Historical draft/template. Use the root README for current implementation status. Unfilled or example figures below are not verified results.

# dbt + Snowflake E-Commerce Analytics Platform

An end-to-end analytics platform on the Brazilian e-commerce (Olist) dataset:
100k-order marketplace data loaded to Snowflake, modeled with dbt Core into a
Kimball star schema plus analysis marts, tested at the source layer, deployed
through GitHub Actions CI with ephemeral schemas, and served to a Tableau Public
dashboard.

**Dashboard:** [TODO: Tableau Public URL after publishing]

## Architecture

```
Olist CSVs (9 files)
   │  scripts/load_raw_data.py (Snowflake connector, PUT + COPY INTO)
   ▼
RAW (OLIST_DB.RAW)                    9 source tables, 26 declared source tests
   │  dbt: views
   ▼
STAGING                               9 models: rename, type, light cleaning
   │  dbt: tables / incremental
   ▼
MARTS                                 4 dims + fct_orders + 3 analysis marts
   │
   ├── dim_customers · dim_products · dim_sellers · dim_dates (dbt_utils.date_spine)
   ├── fct_orders                     order grain; items/payments/reviews aggregated in
   ├── mart_daily_revenue             incremental, 7/30-day rolling windows
   ├── mart_customer_lifetime_value   RANK / NTILE / PERCENT_RANK segmentation
   ├── mart_seller_performance
   └── snapshots/snap_orders_status   SCD2 order-status history
```

## What's deliberately in here

- **Incremental with a lookback window.** `mart_daily_revenue` re-processes a
  trailing 30-day window on each run (`is_incremental()` + dateadd) because its
  rolling averages need history — a plain "new rows only" incremental would
  silently corrupt the window calcs at the boundary. `on_schema_change='fail'`
  because a schema drift in a revenue mart should stop the line, not improvise.
- **Two customer keys, used correctly.** Olist's `customer_id` is per-order;
  `customer_unique_id` is the real identity. Staging documents both; CLV
  aggregates at `customer_unique_id` grain. Most public analyses of this
  dataset get this wrong and overcount "customers" by ~3%.
- **Tests where the data breaks.** 26 source tests (uniqueness, nulls,
  relationships). Two tests are *deliberately omitted* and documented instead:
  `review_id` is not unique in the raw data, and product categories exist with
  no translation row — see `docs/DATA_QUALITY_FINDINGS.md`. A test suite that
  encodes false assumptions about dirty data just teaches you to ignore red.
- **CI on ephemeral schemas.** Every CI run builds into `CI_<github_run_id>`,
  so PRs can't trample each other or dev; source tests gate the merge.
- **SCD2 snapshot** on order status (`snap_orders_status`) — order lifecycle
  history that the raw data overwrites.

## Running it

```bash
pip install dbt-core==1.11.11 dbt-snowflake==1.11.5
python scripts/load_raw_data.py     # loads the 9 Olist CSVs to OLIST_DB.RAW
dbt deps && dbt build               # models + tests + snapshots
dbt docs generate && dbt docs serve
```

Profiles: Snowflake account/user/role/warehouse via environment variables —
see `.github/workflows/dbt_ci.yml` for the exact profile shape CI uses.

## Costs

Runs on an X-Small warehouse with auto-suspend at 60s. Full analysis in
`docs/COST_ANALYSIS.md` [TODO: fill measured credits after a fresh
`dbt build` — queries provided in that doc].

## Repo map

```
models/staging/    9 views + _sources.yml (source contracts + 26 tests)
models/marts/      star schema + 3 marts
snapshots/         SCD2 order status
macros/            days_between_safe, format_money
scripts/           raw loader (Snowflake Python connector)
.github/workflows/ CI: deps -> parse -> compile -> source tests, ephemeral schema
docs/              data-quality findings, cost analysis, decisions
```
