# GSP327: Engineer Data for Predictive Modeling with BigQuery ML: Challenge Lab

## Challenge Scenario

You have started a new role as a **Data Engineer for TaxiCab Inc.** You are expected to import some historical data to a working BigQuery dataset, and build a basic model that predicts fares based on information available when a new ride starts. Leadership is interested in building an app and estimating for users how much a ride will cost. The source data will be provided in your project.

You are expected to have the skills and knowledge for these tasks, so don't expect step-by-step guides to be provided.

## Your Challenge

As soon as you sit down at your desk and open your new laptop you receive your first assignment: build a basic BQML fare prediction model for leadership. Perform the following tasks to import and clean the data, then build the model and perform batch predictions with new data so that leadership can review model performance and make a go/no-go decision on deploying the app functionality.

---

### Task 1. Clean your training data

You've already completed the first step, and have created a dataset `taxirides` and imported the historical data to table, `historical_taxi_rides_raw`. This is data prior for rides to 2015.

**Note:** You may need to wait 1-3 minutes for the data to be fully populated in your project.

To complete this task you will need to:
* Clean the data in `historical_taxi_rides_raw` and make a copy to **Table** in the same dataset. You can use BigQuery, Dataprep, Dataflow, etc. to create this table and clean the data. Make sure your target column is called `Fare amount`.

**Data cleaning tasks:**
* Ensure `trip_distance` is greater than Number.
* Remove rows where `fare_amount` is very small (less than $Value for example).
* Ensure that the latitudes and longitudes are reasonable for the use case.
* Ensure `passenger_count` is greater than Number.
* Be sure to add `tolls_amount` and `fare_amount` to **Fare amount** as the target variable since `total_amount` includes tips.
* Because the source dataset is large (>1 Billion rows), sample the dataset to less than 1 Million rows.
* Only copy fields that will be used in your model (`report_prediction_data` is a good guide).

Click **Check my progress** to verify the objective.
Create a cleaned copy of the data in **Table**

---

### Task 2. Create a BigQuery ML model

Based on the data you have in **Table**, build a BigQuery ML model that predicts **Fare amount**.

Call the model **Fare**.

**Note:** Your model will need an **RMSE of 10 or less** to complete the task.

**Some helpful hints:**
* You can encapsulate any additional data transformations in a `TRANSFORM()` clause
* Keep in mind, only features in the `TRANSFORM()` clause will be passed to the model. You can use a `* EXCEPT(feature_to_leave_out)` to pass some or all of the features without explicitly calling them
* `ST_distance()` and `ST_GeogPoint()` GIS functions in BigQuery can be used to easily calculate euclidean distance (i.e. how far pickup to dropoff did the taxi travel):

    ST_Distance(ST_GeogPoint(pickuplon, pickuplat),
    ST_GeogPoint(dropofflon, dropofflat)) AS euclidean

Click **Check my progress** to verify the objective.
Create BigQuery ML model **Fare** with RMSE 10 or less

---

### Task 3. Perform a batch prediction on new data

Leadership is curious to see how well your model performs over new data, in this case, all of the data they've collected in 2015. This data is in `taxirides.report_prediction_data`. Only values known at prediction time are included in the table.

Use `ML.PREDICT` and your model to predict **Fare amount** and store your results in a table called `2015_fare_amount_predictions`.

Click **Check my progress** to verify the objective.
Perform batch predictions and store in a new table `2015_fare_amount_predictions`