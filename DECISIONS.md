# DECISIONS.md — for the repo's docs/

Design decisions and the reasoning, written for a reviewer who wants to know
whether choices were made or defaulted into.

## Modeling

**Star schema at order grain, not order-item grain.** `fct_orders` aggregates
items, payments, and reviews to one row per order. Trade-off: item-level
questions (product mix within an order) need staging; in exchange, every
dashboard query is a single-table scan or one dim join, and the revenue
definitions live in exactly one place. Given the dashboard workload, order
grain wins. An `fct_order_items` companion fact is the natural next model if
product analytics becomes a first-class need.

**`customer_unique_id` as the CLV grain.** Olist ships two customer keys:
`customer_id` (per order) and `customer_unique_id` (per person). CLV at
`customer_id` grain would make every customer a one-time buyer by construction.
Documented in `_sources.yml` so nobody re-learns it the hard way.

**Reviews aggregated with AVG + any-positive/any-negative flags.** Some orders
carry multiple reviews (see data-quality findings). Averaging the score and
keeping boolean flags preserves the signal without inventing a "true" review.

**`dim_dates` via `dbt_utils.date_spine`.** Zero-order days must exist as rows,
or rolling averages and week-over-week comparisons silently skip days.

## Materialization

**Staging = views.** They're cheap renames/typecasts read only by dbt builds;
storing them would buy nothing and add staleness.

**Marts = tables; `mart_daily_revenue` = incremental.** The daily mart is the
one with real growth (a row per day, recomputed hourly in a production
scenario). Incremental config re-processes a trailing 30-day window because
the mart contains 7- and 30-day window functions — an append-only incremental
would freeze the rolling averages wrong at the boundary. `unique_key=
'order_date'` makes the window overwrite idempotent. `on_schema_change='fail'`:
revenue schema drift should be a human decision.

**SCD2 snapshot on order status.** The source overwrites status in place;
`snap_orders_status` (dbt snapshot, check strategy) keeps the history that
questions like "how long do orders sit in 'shipped'?" require.

## Testing

**Source-level tests as the contract with the loader.** 26 tests: PK
uniqueness/not-null on every entity table, FK relationships into orders/
products/sellers. They run first in CI, so a bad load fails before any model
builds on it.

**Deliberate omissions, documented.** No `unique` on `review_id` (raw data
reuses review records across orders) and no relationship test from products to
the category-translation table (untranslated categories exist). Encoding false
cleanliness assumptions produces permanently red tests that train people to
ignore the suite — the findings doc carries these instead.

## CI/CD

**Ephemeral per-run schemas (`CI_<run_id>`).** Concurrent PRs can't collide,
and a failed run leaves debuggable artifacts instead of a half-mutated shared
schema. Cleanup is a scheduled drop of `CI_%` schemas older than N days.

**CI runs parse → compile → source tests, not a full build.** On this dataset
a full `dbt build` per PR would be slow and spend credits to rebuild marts the
PR may not touch. Source tests + compile catch the classes of failure PRs
actually introduce (broken refs, YAML drift, contract violations). Full builds
happen on merge to main. Known gap when the project grows: switch to
state-based selection (`dbt build --select state:modified+`) with a stored
manifest, which tests exactly what changed and nothing else.

**Auth: password via GitHub secrets** — fine for a portfolio single-user
account; a production setup would use key-pair auth and a dedicated CI service
user with a scoped role.

## Warehouse

**X-Small + 60s auto-suspend.** The full dataset is ~100k orders; nothing here
needs more than X-Small, and suspend-fast is the single highest-leverage cost
control on Snowflake. Numbers in COST_ANALYSIS.md.
