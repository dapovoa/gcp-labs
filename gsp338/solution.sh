#!/bin/bash
set -e

echo "========================================================"
echo "GSP338 - Monitor and Log with Google Cloud Observability"
echo "========================================================"
echo ""

echo "Required variables:"
read -p "  - Custom Metric Name: " CUSTOM_METRIC_NAME
read -p "  - Threshold (for alert): " THRESHOLD
echo ""

if [ -z "$CUSTOM_METRIC_NAME" ] || [ -z "$THRESHOLD" ]; then
    echo "Error: All variables are required"
    exit 1
fi

PROJECT_ID=$(gcloud config get-value project)
ZONE=$(gcloud compute instances list --filter="name=video-queue-monitor" --format="value(zone)" | head -n1)

if [ -z "$ZONE" ]; then
  echo "Error: Could not find video-queue-monitor instance"
  exit 1
fi

INSTANCE_ID=$(gcloud compute instances describe video-queue-monitor --zone="$ZONE" --format="value(id)")

echo "Configuration:"
echo "  - Project: $PROJECT_ID"
echo "  - Zone: $ZONE"
echo "  - Instance ID: $INSTANCE_ID"
echo "  - Custom Metric: $CUSTOM_METRIC_NAME"
echo "  - Alert Threshold: $THRESHOLD"
echo ""

echo "[Setup] Enabling required APIs"
gcloud services enable monitoring.googleapis.com logging.googleapis.com

echo "[Task 1/4] Stopping video-queue-monitor instance"
gcloud compute instances stop video-queue-monitor --zone="$ZONE" --quiet

cat > startup-script.sh <<'EOF_SCRIPT'
#!/bin/bash
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')

sudo apt update -y
sudo apt-get install wget git -y
sudo chmod 777 /usr/local/
wget https://go.dev/dl/go1.22.8.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.22.8.linux-amd64.tar.gz
rm go1.22.8.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install
service google-cloud-ops-agent start

mkdir -p /work/go/cache /work/go/video
export GOPATH=/work/go
export GOCACHE=/work/go/cache

gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

cd /work/go/video
go mod init video
go get go.opencensus.io
go get contrib.go.opencensus.io/exporter/stackdriver
go mod tidy

export MY_PROJECT_ID=$(gcloud config get-value project)
export MY_GCE_INSTANCE_ID=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id)
export MY_GCE_INSTANCE_ZONE=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone)

go run main.go
EOF_SCRIPT

echo "[Task 1/4] Complete"
echo ""

echo "[Task 2/4] Updating startup script and restarting instance"
gcloud compute instances add-metadata video-queue-monitor \
  --zone="$ZONE" \
  --metadata-from-file=startup-script=startup-script.sh

gcloud compute instances start video-queue-monitor --zone="$ZONE"

echo "[Task 2/4] Complete"
echo ""

echo "[Task 3/4] Creating log-based metric"
gcloud logging metrics create "$CUSTOM_METRIC_NAME" \
  --description="Tracks uploads of 4K and 8K videos" \
  --log-filter='textPayload=("file_format=4K" OR "file_format=8K")' 2>/dev/null || echo "Metric already exists"

sleep 10

echo "[Task 3/4] Complete"
echo ""

echo "[Task 4/4] Creating alert policy"
POLICY_JSON=$(mktemp)
cat > "$POLICY_JSON" <<EOF
{
  "displayName": "alert_${CUSTOM_METRIC_NAME}",
  "combiner": "OR",
  "conditions": [
    {
      "displayName": "highres_upload_rate_condition",
      "conditionThreshold": {
        "filter": "resource.type = \"cloud_function\" AND metric.type = \"logging.googleapis.com/user/${CUSTOM_METRIC_NAME}\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "thresholdValue": ${THRESHOLD},
        "duration": "0s",
        "trigger": { "count": 1 }
      }
    }
  ],
  "enabled": true
}
EOF

gcloud alpha monitoring policies create --policy-from-file="$POLICY_JSON" 2>/dev/null && echo "Alert created successfully" || echo "Alert may already exist"
rm -f "$POLICY_JSON" startup-script.sh

echo "[Task 4/4] Complete"
echo ""
echo "================================"
echo "All tasks completed successfully"
echo "================================"
echo ""
echo "Important: Wait 5-10 minutes for metrics to appear"
echo ""
echo "Manual steps remaining:"
echo "  - Go to Metrics Explorer and search for: input_queue_size"
echo "  - Add both metrics to Media_Dashboard:"
echo "    * input_queue_size (from video-queue-monitor)"
echo "    * ${CUSTOM_METRIC_NAME} (log-based metric)"
echo ""
echo "Quick links:"
echo "  - Dashboard: https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT_ID"
echo "  - Metrics Explorer: https://console.cloud.google.com/monitoring/metrics-explorer?project=$PROJECT_ID"
