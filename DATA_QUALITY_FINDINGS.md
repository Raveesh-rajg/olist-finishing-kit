# DATA_QUALITY_FINDINGS.md — for the repo's docs/

Findings from profiling the raw Olist data. Each finding: evidence query,
measured result (run it, paste the number, remove TODO), and the modeling
decision it drove. This doc is referenced from `_sources.yml` where tests were
deliberately omitted.

## 1. `review_id` is not unique

```sql
SELECT COUNT(*) AS dup_review_rows
FROM (
  SELECT review_id FROM RAW.olist_order_reviews_dataset
  GROUP BY review_id HAVING COUNT(*) > 1
);
```
Measured: **TODO** duplicated review_ids.

Olist reused review records across orders. Decision: no `unique` test on
`review_id` (it would be permanently red); `fct_orders` aggregates reviews per
order with AVG(score) + any-positive/any-negative flags instead of assuming
one review per order.

## 2. Orders can carry multiple reviews; some carry none

```sql
SELECT n_reviews, COUNT(*) AS orders
FROM (SELECT order_id, COUNT(*) AS n_reviews
      FROM RAW.olist_order_reviews_dataset GROUP BY order_id) t
GROUP BY n_reviews ORDER BY n_reviews;
```
Measured distribution: **TODO**.

Decision: review aggregation in `fct_orders` (see finding 1); review coverage
is a LEFT JOIN, never INNER — an inner join would silently drop unreviewed
orders from revenue.

## 3. Untranslated product categories

```sql
SELECT COUNT(DISTINCT p.product_category_name) AS untranslated
FROM RAW.olist_products_dataset p
LEFT JOIN RAW.product_category_name_translation t
  ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;
```
Measured: **TODO** categories with no English translation.

Decision: relationship test deliberately omitted; `dim_products` falls back to
the Portuguese name (COALESCE) rather than dropping or nulling the category.

## 4. Geolocation has many rows per zip prefix

```sql
SELECT COUNT(*) AS raw_rows,
       COUNT(DISTINCT geolocation_zip_code_prefix) AS distinct_zips
FROM RAW.olist_geolocation_dataset;
```
Measured: **TODO** raw rows vs **TODO** distinct prefixes.

The file is GPS samples, not a zip dimension. Decision: `stg_geolocation`
dedupes to one centroid per prefix (AVG lat/lon) — documented so the precision
loss is a known choice.

## 5. Delivered orders with missing timestamps

```sql
SELECT COUNT(*) FROM RAW.olist_orders_dataset
WHERE order_status = 'delivered'
  AND (order_delivered_customer_date IS NULL
       OR order_approved_at IS NULL);
```
Measured: **TODO** delivered orders missing delivery/approval timestamps.

Decision: the `days_between_safe` macro null-guards every duration calc, so
delivery-time metrics skip these rows instead of erroring or producing
negative garbage; `was_delivered_late` treats unknown as not-late (documented
bias, small n).

## 6. Misspelled source columns

`product_name_lenght`, `product_description_lenght` — misspelled in the source
CSV headers. Decision: staging renames to correct spelling exactly once;
nothing downstream ever sees the typo. (This is what staging layers are for.)

## Summary table

| # | finding | test strategy | modeling response |
|---|---|---|---|
| 1 | review_id reused | unique test omitted, documented | AVG + flags per order |
| 2 | 0..n reviews per order | — | LEFT JOIN aggregation |
| 3 | untranslated categories | relationship test omitted | COALESCE fallback |
| 4 | geo = GPS samples | — | centroid dedup in staging |
| 5 | missing delivered timestamps | — | null-safe duration macro |
| 6 | misspelled columns | — | rename once in staging |
