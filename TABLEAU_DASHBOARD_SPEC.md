# Tableau Public dashboard — build specification

Three tabs on the three marts. This spec is complete enough to build without
design decisions left open; deviate where taste says to, not where it's easier.

## 0. Connection strategy (decide this first)

**Tableau Public cannot live-connect to Snowflake.** Public only saves extracts
from file-based sources. Two workable paths:

- **Recommended: CSV extracts.** Run `export_marts_for_tableau.sql` in Snowsight,
  download the three result sets as CSV, connect Tableau to the CSVs, publish.
  Free, repeatable, and honest about what Public supports. Document the export
  date on the dashboard (small caption: "data as of YYYY-MM-DD").
- If you have Tableau Desktop (trial): connect to Snowflake directly, build,
  then "Save to Tableau Public" — Desktop converts to an extract on publish.
  Same result, nicer authoring.

Join strategy: don't join in Tableau. Each tab uses ONE mart as its primary
source (they're already at dashboard grain — that's what the marts are *for*).
Relate `mart_daily_revenue` and `fct_orders` extracts only if you add the
drill-through action in Tab 1 (relationship on order date).

## Tab 1 — Revenue Trends (source: mart_daily_revenue)

Layout: KPI band across the top, main trend chart center (2/3 height),
day-of-week heatmap bottom-left, late-delivery trend bottom-right.

**KPI band** (4 tiles): total revenue, total orders, avg daily revenue,
% late orders. Each is a single-value worksheet with a comparison caption vs.
the prior period (table calc: `LOOKUP(SUM(...), -1)`).

**Main chart:** dual-axis line. Axis 1: `daily_revenue` as bars (60% opacity);
axis 2: `revenue_7day_avg` and `revenue_30day_avg` as lines. The rolling
averages come from the mart (window functions in dbt), NOT Tableau table calcs —
put that in the tooltip caption; it's a talking point (semantics live in the
warehouse, every BI tool shows the same numbers).

**Parameter:** `p_ma_window` (list: 7-day / 30-day / both) controlling which
average lines show, via a calculated field filter. This is the parameter story
for the tab.

**Heatmap:** `WEEKDAY(order_date)` rows × `MONTH(order_date)` columns, color =
`SUM(daily_revenue)`. Brazilian e-commerce shows a strong weekday skew; annotate
the strongest cell.

**Action:** date-range brush on the main chart filters the heatmap + KPI band.

## Tab 2 — Customer & CLV Segmentation (source: mart_customer_lifetime_value)

Layout: segment summary bar top-left, scatter center, state map right.

**Segment bar:** `customer_segment` (top_10_pct / top_30_pct / top_50_pct /
bottom_50_pct — already computed in the mart) vs. `SUM(lifetime_revenue)` and
`COUNT(customer_unique_id)` side by side. The point the chart must make: the
top decile's revenue share. Label it explicitly.

**Scatter:** X = `lifetime_orders`, Y = `lifetime_revenue`, one mark per
customer is too many points for Public performance — aggregate to
`revenue_decile` × `customer_state` cells; size = customers, color = decile.

**LOD showcase (this tab's interview talking point):**
```
// % of state's revenue held by that state's top decile
{ FIXED [Customer State] :
  SUM(IF [Revenue Decile] = 1 THEN [Lifetime Revenue] END) }
/ { FIXED [Customer State] : SUM([Lifetime Revenue]) }
```
Map: filled map of Brazil, color = that LOD field. The insight: whether revenue
concentration is uniform across states or coastal-metro heavy.

**Parameter:** `p_segment_metric` (revenue / customers / avg order value)
switching the segment bar's measure via CASE calculated field.

## Tab 3 — Seller Performance (source: mart_seller_performance)

Layout: ranked bar-in-table left (top 20 sellers), quadrant scatter right.

**Ranked list:** top 20 sellers by revenue, bars inline, with review score and
late-shipment % as text columns. Rank via `RANK(SUM(revenue))` table calc.

**Quadrant scatter:** X = avg review score, Y = revenue, reference lines at
median of each → four quadrants. Annotate the interesting quadrant (high
revenue + low review = retention risk). Color = late-shipment rate.

**Action:** clicking a seller in the ranked list highlights it in the scatter.

## Global

- Single color family; red reserved exclusively for "late/negative".
- Every tab: caption with data-as-of date + "built on dbt marts in Snowflake".
- Publish name: "Olist E-Commerce Analytics — dbt + Snowflake portfolio project".
- Before publishing: File > Workbook Locale = English; hide all raw-field
  tooltips you didn't write.

## Checklist

- [ ] Run export SQL, save 3 CSVs (note row counts — they go in the README)
- [ ] Build Tab 1, 2, 3 per spec
- [ ] Mobile layout check (Public renders phone layouts by default)
- [ ] Publish, set "Show sheets as tabs", grab the public URL
- [ ] Add URL + a screenshot per tab to the repo README
