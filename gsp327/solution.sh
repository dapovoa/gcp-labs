#!/bin/bash
set -e

echo "==============================================================="
echo "GSP327 - Engineer Data for Predictive Modeling with BigQuery ML"
echo "==============================================================="
echo ""

echo "Required variables:"
read -p "  - Table Name: " CLEANED_TABLE_NAME
read -p "  - Fare Amount: " FARE_COLUMN
read -p "  - Number (if empty, press Enter for default 0): " NUMBER
read -p "  - Example Value: " EXAMPLE_VALUE
read -p "  - Model Name: " MODEL_NAME
echo ""

NUMBER=${NUMBER:-0}

if [ -z "$CLEANED_TABLE_NAME" ] || [ -z "$FARE_COLUMN" ] || [ -z "$MODEL_NAME" ] || [ -z "$EXAMPLE_VALUE" ]; then
    echo "Error: Required variables missing"
    exit 1
fi

DATASET="taxirides"

echo "Configuration:"
echo "  - Table: $CLEANED_TABLE_NAME"
echo "  - Fare Column: $FARE_COLUMN"
echo "  - Number: $NUMBER"
echo "  - Example Value: $EXAMPLE_VALUE"
echo "  - Model: $MODEL_NAME"
echo ""

echo "[Task 1/3] Cleaning data"

bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$DATASET.$CLEANED_TABLE_NAME\` AS
SELECT
  pickup_datetime,
  pickup_longitude AS pickuplon,
  pickup_latitude AS pickuplat,
  dropoff_longitude AS dropofflon,
  dropoff_latitude AS dropofflat,
  passenger_count AS passengers,
  (fare_amount + tolls_amount) AS $FARE_COLUMN
FROM
  \`taxirides.historical_taxi_rides_raw\`
WHERE
  trip_distance > $NUMBER
  AND fare_amount >= $EXAMPLE_VALUE
  AND passenger_count > $NUMBER
  AND pickup_latitude BETWEEN 40.5 AND 41.0
  AND pickup_longitude BETWEEN -74.5 AND -73.5
  AND dropoff_latitude BETWEEN 40.5 AND 41.0
  AND dropoff_longitude BETWEEN -74.5 AND -73.5
  AND MOD(ABS(FARM_FINGERPRINT(CAST(pickup_datetime AS STRING))), 1000) = 1;"

echo "[Task 1/3] Complete"
echo ""

echo "[Task 2/3] Creating model"

bq query --use_legacy_sql=false \
"CREATE OR REPLACE MODEL \`$DATASET.$MODEL_NAME\`
TRANSFORM(
  ST_Distance(ST_GeogPoint(pickuplon, pickuplat),
              ST_GeogPoint(dropofflon, dropofflat)) AS euclidean,
  CAST(EXTRACT(DAYOFWEEK FROM pickup_datetime) AS INT64) AS dayofweek,
  CAST(EXTRACT(HOUR FROM pickup_datetime) AS INT64) AS hourofday,
  pickuplon,
  pickuplat,
  dropofflon,
  dropofflat,
  passengers,
  $FARE_COLUMN
)
OPTIONS(
  model_type='linear_reg',
  input_label_cols=['$FARE_COLUMN']
) AS
SELECT * FROM \`$DATASET.$CLEANED_TABLE_NAME\`;"

echo "[Task 2/3] Complete (waiting 180s for model training)"
sleep 180
echo ""

echo "[Task 3/3] Creating batch prediction"

bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$DATASET.2015_fare_amount_predictions\` AS
SELECT * FROM ML.PREDICT(
  MODEL \`$DATASET.$MODEL_NAME\`,
  (SELECT * FROM \`taxirides.report_prediction_data\`)
);"

echo "[Task 3/3] Complete"
echo ""
echo "================================"
echo "All tasks completed successfully"
echo "================================"
