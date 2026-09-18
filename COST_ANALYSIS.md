> Historical draft/template. Use the root README for current implementation status. Unfilled or example figures below are not verified results.

# COST_ANALYSIS.md — for the repo's docs/

Every number in this doc must come from your own account. Run the queries,
paste results, delete the TODO markers. Do not publish with placeholders.

## Setup being measured

X-Small warehouse ($2-ish/credit list price, 1 credit/hour running),
auto-suspend 60s, auto-resume on. Workload: full `dbt build` (staging views +
marts + snapshot + tests), plus CI runs (parse/compile/source tests).

## 1. What does a full `dbt build` cost?

Run a fresh `dbt build`, wait a few minutes for metering to land, then:

```sql
-- total compute seconds + credits for the build window
SELECT
    warehouse_name,
    SUM(credits_used)                    AS credits,
    SUM(credits_used) * 2.0              AS approx_usd   -- adjust to your rate
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= '<build start timestamp>'
  AND start_time <  '<build end timestamp + 5 min>'
GROUP BY warehouse_name;
```

Result: **TODO** credits ≈ $**TODO** per full build.

## 2. Which models cost the most?

```sql
SELECT
    query_tag,                              -- dbt sets model info if configured
    total_elapsed_time / 1000 AS seconds,
    query_text
FROM snowflake.account_usage.query_history
WHERE start_time >= '<build start>'
  AND query_type IN ('CREATE_TABLE_AS_SELECT', 'MERGE', 'INSERT')
ORDER BY total_elapsed_time DESC
LIMIT 10;
```

Expected shape (verify): `fct_orders` and `mart_customer_lifetime_value`
dominate — the two models with joins/windows over the full order set.
Result: **TODO** table of top-5 with seconds.

## 3. What did incremental buy us?

Full-refresh vs incremental runtime for `mart_daily_revenue`:

```bash
dbt run --select mart_daily_revenue --full-refresh   # time it
dbt run --select mart_daily_revenue                  # time it (incremental)
```

Result: **TODO**s full vs **TODO**s incremental. Honest note for the writeup:
at 100k orders this saves seconds, not dollars — the point of the pattern is
that at 100M orders it's the difference between a workable hourly refresh and
an unpayable one. Say exactly that; don't inflate the demo-scale saving.

## 4. Monthly steady-state estimate

Assume: N builds/day (your CI cadence + a daily scheduled build).

```
monthly_credits ≈ builds_per_day × 30 × credits_per_build      = TODO
monthly_usd     ≈ monthly_credits × your_effective_rate        = TODO
storage: SELECT SUM(active_bytes)/POWER(1024,3) AS gb
         FROM snowflake.account_usage.table_storage_metrics
         WHERE table_catalog = 'OLIST_DB';                     = TODO GB (≈ $/mo TODO)
```

## 5. The cost decisions that matter (talking points)

1. **Auto-suspend 60s** — idle X-Small left running is ~720 credits/month;
   suspend makes the platform cost proportional to work done.
2. **CI does not full-build** — parse/compile/source-test per PR; full build
   only on merge. Biggest recurring saving in the setup.
3. **Staging as views** — zero storage, zero rebuild compute for renames.
4. **Incremental where growth lives** — see §3 for the honest framing.
