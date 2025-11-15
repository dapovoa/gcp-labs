#!/bin/bash
set -e

echo "=========================================="
echo "GSP341 - Create ML Models with BigQuery ML"
echo "=========================================="
echo ""

PROJECT_ID=$(gcloud config get-value project)

echo "Configuration:"
echo "  - Project ID: $PROJECT_ID"
echo ""

echo "[Task 1/4] Creating dataset and customer_classification_model"

bq mk --dataset ${PROJECT_ID}:ecommerce

bq query --use_legacy_sql=false \
"CREATE OR REPLACE MODEL \`ecommerce.customer_classification_model\`
OPTIONS
(
  model_type='logistic_reg',
  labels = ['will_buy_on_return_visit']
)
AS
SELECT
  * EXCEPT(fullVisitorId)
FROM
(SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
FROM
    \`data-to-insights.ecommerce.web_analytics\`
WHERE
    totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430')
JOIN
(SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
FROM
    \`data-to-insights.ecommerce.web_analytics\`
GROUP BY fullvisitorid)
USING (fullVisitorId);"

echo "[Task 1/4] Complete"
echo ""

echo "[Task 2/4] Evaluating customer_classification_model"

bq query --use_legacy_sql=false \
"SELECT
  roc_auc,
  CASE
    WHEN roc_auc > .9 THEN 'good'
    WHEN roc_auc > .8 THEN 'fair'
    WHEN roc_auc > .7 THEN 'decent'
    WHEN roc_auc > .6 THEN 'not great'
  ELSE 'poor' END AS model_quality
FROM
  ML.EVALUATE(MODEL ecommerce.customer_classification_model,  (
SELECT
  * EXCEPT(fullVisitorId)
FROM
  (SELECT
      fullVisitorId,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
      \`data-to-insights.ecommerce.web_analytics\`
  WHERE
      totals.newVisits = 1
      AND date BETWEEN '20170501' AND '20170630')
  JOIN
  (SELECT
      fullvisitorid,
      IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
      \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid)
  USING (fullVisitorId)
));"

echo "[Task 2/4] Complete"
echo ""

echo "[Task 3/4] Creating improved_customer_classification_model"

bq query --use_legacy_sql=false \
"CREATE OR REPLACE MODEL \`ecommerce.improved_customer_classification_model\`
OPTIONS
  (model_type='logistic_reg', labels = ['will_buy_on_return_visit']) AS
WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid
)
SELECT * EXCEPT(unique_session_id) FROM (
  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
      will_buy_on_return_visit,
      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      IFNULL(totals.pageviews, 0) AS pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      IFNULL(geoNetwork.country, \"\") AS country
  FROM \`data-to-insights.ecommerce.web_analytics\`,
    UNNEST(hits) AS h
    JOIN all_visitor_stats USING(fullvisitorid)
  WHERE 1=1
    AND totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430'
  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
);"

echo "Evaluating improved model"

bq query --use_legacy_sql=false \
"SELECT
  roc_auc,
  CASE
    WHEN roc_auc > .9 THEN 'good'
    WHEN roc_auc > .8 THEN 'fair'
    WHEN roc_auc > .7 THEN 'decent'
    WHEN roc_auc > .6 THEN 'not great'
  ELSE 'poor' END AS model_quality
FROM
  ML.EVALUATE(MODEL ecommerce.improved_customer_classification_model,  (
WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid
)
SELECT * EXCEPT(unique_session_id) FROM (
  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
      will_buy_on_return_visit,
      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      IFNULL(totals.pageviews, 0) AS pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      IFNULL(geoNetwork.country, \"\") AS country
  FROM \`data-to-insights.ecommerce.web_analytics\`,
    UNNEST(hits) AS h
    JOIN all_visitor_stats USING(fullvisitorid)
  WHERE 1=1
    AND totals.newVisits = 1
    AND date BETWEEN '20170501' AND '20170630'
  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
)
));"

echo "[Task 3/4] Complete"
echo ""

echo "[Task 4/4] Creating finalized_classification_model and making predictions"

bq query --use_legacy_sql=false \
"CREATE OR REPLACE MODEL \`ecommerce.finalized_classification_model\`
OPTIONS
  (model_type='logistic_reg', labels = ['will_buy_on_return_visit']) AS
WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid
)
SELECT * EXCEPT(unique_session_id) FROM (
  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
      will_buy_on_return_visit,
      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      IFNULL(totals.pageviews, 0) AS pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      IFNULL(geoNetwork.country, \"\") AS country
  FROM \`data-to-insights.ecommerce.web_analytics\`,
    UNNEST(hits) AS h
    JOIN all_visitor_stats USING(fullvisitorid)
  WHERE 1=1
    AND totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430'
  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
);"

echo "Making predictions on last month data"

bq query --use_legacy_sql=false \
"SELECT
  *
FROM
  ml.PREDICT(MODEL \`ecommerce.finalized_classification_model\`,
   (
WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid
)
SELECT
    CONCAT(fullvisitorid, '-',CAST(visitId AS STRING)) AS unique_session_id,
    will_buy_on_return_visit,
    MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site,
    IFNULL(totals.pageviews, 0) AS pageviews,
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    device.deviceCategory,
    IFNULL(geoNetwork.country, \"\") AS country
FROM \`data-to-insights.ecommerce.web_analytics\`,
  UNNEST(hits) AS h
  JOIN all_visitor_stats USING(fullvisitorid)
WHERE
  totals.newVisits = 1
  AND date BETWEEN '20170701' AND '20170801'
GROUP BY
unique_session_id,
will_buy_on_return_visit,
bounces,
time_on_site,
totals.pageviews,
trafficSource.source,
trafficSource.medium,
channelGrouping,
device.deviceCategory,
country
))
ORDER BY
  predicted_will_buy_on_return_visit DESC;"

echo "[Task 4/4] Complete"
echo ""
echo "================================"
echo "All tasks completed successfully"
echo "================================"
