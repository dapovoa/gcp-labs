# GSP341: Create ML Models with BigQuery ML: Challenge Lab

## Challenge Scenario

You have started a new role as a junior member of the Data Science department, expected to help with the development and assessment of datasets and machine learning models to help provide insights based on real work data sets.

You are expected to have the skills and knowledge for these tasks, so don't expect step-by-step guides to be provided.

The following tasks in this lab check your knowledge related to BigQuery and machine learning.

---

## Task 1. Create a new dataset and machine learning model

You must create a dataset with the dataset ID **ecommerce** and then create the machine learning model `customer_classification_model` to predict performance.

Run the following query to create the `customer_classification_model`:

    CREATE OR REPLACE MODEL `ecommerce.customer_classification_model`
      OPTIONS
      (
      model_type='logistic_reg',
      labels = ['will_buy_on_return_visit']
      )
      AS

      #standardSQL
      SELECT
      * EXCEPT(fullVisitorId)
      FROM

      # features
      (SELECT
          fullVisitorId,
          IFNULL(totals.bounces, 0) AS bounces,
          IFNULL(totals.timeOnSite, 0) AS time_on_site
      FROM
          `data-to-insights.ecommerce.web_analytics`
      WHERE
          totals.newVisits = 1
          AND date BETWEEN '20160801' AND '20170430') # train on first 9 months
      JOIN
      (SELECT
          fullvisitorid,
          IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
      FROM
          `data-to-insights.ecommerce.web_analytics`
      GROUP BY fullvisitorid)
      USING (fullVisitorId);

Click **Check my progress** to verify the objective.
Check a new dataset and model has been created

---

## Task 2. Evaluate classification model performance

Evaluate the performance of the `customer_classification_model` against new unseen evaluation data using `ML.EVALUATE`.

In BigQuery ML, `roc_auc` is simply a queryable field when evaluating your trained ML model. Run the query to evaluate how well the model performs.

Click **Check my progress** to verify the objective.
Confirm that both machine learning models have been evaluated.

---

## Task 3. Improve model performance with Feature Engineering and Evaluate the model

Use dataset features that may help the model better understand the relationship between a visitor's first session and the likelihood that they purchase on a subsequent visit.

Add new features and create a second machine learning model called **improved_customer_classification_model**.

**New features to add:**
* How far the visitor got in the checkout process on their first visit
* Where the visitor came from (traffic source: organic search, referring site, etc..)
* Device category (mobile, tablet, desktop)
* Geographic information (country)

Evaluate the newly created model to see if there is better predictive power than `customer_classification_model`.

Click **Check my progress** to verify the objective.
Improve model performance and evaluate the model.

---

## Task 4. Predict which new visitors will come back and purchase

Create the machine learning model **finalized_classification_model** and then write a query to predict which new visitors will come back and make a purchase.

Run the following query to create the `finalized_classification_model`:

    CREATE OR REPLACE MODEL `ecommerce.finalized_classification_model`
    OPTIONS
      (model_type="logistic_reg", labels = ["will_buy_on_return_visit"]) AS

    WITH all_visitor_stats AS (
    SELECT
      fullvisitorid,
      IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
      FROM `data-to-insights.ecommerce.web_analytics`
      GROUP BY fullvisitorid
    )

    # add in new features
    SELECT * EXCEPT(unique_session_id) FROM (

      SELECT
          CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,

          # labels
          will_buy_on_return_visit,

          MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

          # behavior on the site
          IFNULL(totals.bounces, 0) AS bounces,
          IFNULL(totals.timeOnSite, 0) AS time_on_site,
          IFNULL(totals.pageviews, 0) AS pageviews,

          # where the visitor came from
          trafficSource.source,
          trafficSource.medium,
          channelGrouping,

          # mobile or desktop
          device.deviceCategory,

          # geographic
          IFNULL(geoNetwork.country, "") AS country

      FROM `data-to-insights.ecommerce.web_analytics`,
      UNNEST(hits) AS h

        JOIN all_visitor_stats USING(fullvisitorid)

      WHERE 1=1
        # only predict for new visits
        AND totals.newVisits = 1
        AND date BETWEEN "20160801" AND "20170430" # train 9 months

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
    );

Write a query to predict which new visitors will come back and make a purchase.
* The query uses the `finalized_classification_model` model to predict the probability that a first-time visitor to the Google Merchandise Store will make a purchase on a later visit.
* You have to make the predictions in the **last 1 month** (out of 12 months) of the dataset.

Click **Check my progress** to verify the objective.
Predict which new visitors will come back and purchase