#!/bin/bash
set -e

echo "=============================================================="
echo "GSP342 - Implement Cloud Security Fundamentals on Google Cloud"
echo "=============================================================="
echo ""

echo "Required variables:"
read -p "  - Custom Security Role: " CUSTOM_ROLE_ID
read -p "  - Service Account: " SERVICE_ACCOUNT_NAME
read -p "  - Cluster Name: " CLUSTER_NAME
echo ""

if [ -z "$CUSTOM_ROLE_ID" ] || [ -z "$SERVICE_ACCOUNT_NAME" ] || [ -z "$CLUSTER_NAME" ]; then
    echo "Error: All variables required"
    exit 1
fi

PROJECT_ID=$(gcloud config get-value project)
REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

if [ -z "$ZONE" ]; then
    ZONE=$(gcloud compute instances list --filter="name:orca-jumphost" --format="value(zone)")
fi

SA_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Configuration:"
echo "  - Project: $PROJECT_ID"
echo "  - Zone: $ZONE"
echo "  - Custom Role: $CUSTOM_ROLE_ID"
echo "  - Service Account: $SA_EMAIL"
echo "  - Cluster: $CLUSTER_NAME"
echo ""

echo "[Task 1/5] Creating custom IAM role"

gcloud iam roles create $CUSTOM_ROLE_ID \
  --project=$PROJECT_ID \
  --title="Custom Storage Editor Role" \
  --description="Custom role for GKE cluster storage access" \
  --permissions="storage.buckets.get,storage.objects.get,storage.objects.list,storage.objects.update,storage.objects.create" \
  --stage=GA

echo "[Task 1/5] Complete"
echo ""

echo "[Task 2/5] Creating service account"

gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --display-name="Orca GKE Service Account"

echo "[Task 2/5] Complete"
echo ""

echo "[Task 3/5] Binding roles to service account"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/monitoring.viewer" --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/monitoring.metricWriter" --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/logging.logWriter" --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="projects/$PROJECT_ID/roles/$CUSTOM_ROLE_ID" --quiet

echo "[Task 3/5] Complete"
echo ""

echo "[Task 4/5] Creating private GKE cluster (5-10 minutes)"

JUMPHOST_IP=$(gcloud compute instances describe orca-jumphost \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].networkIP)')

if [ -z "$JUMPHOST_IP" ]; then
    echo "Error: Could not find orca-jumphost IP"
    exit 1
fi

JUMPHOST_CIDR="${JUMPHOST_IP}/32"
echo "Jumphost authorized network: $JUMPHOST_CIDR"

gcloud container clusters create $CLUSTER_NAME \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --service-account=$SA_EMAIL \
  --network=orca-build-vpc \
  --subnetwork=orca-build-subnet \
  --enable-private-nodes \
  --enable-private-endpoint \
  --enable-ip-alias \
  --enable-master-authorized-networks \
  --master-authorized-networks=$JUMPHOST_CIDR \
  --no-enable-basic-auth \
  --no-issue-client-certificate \
  --machine-type=e2-medium \
  --num-nodes=1 \
  --logging=SYSTEM,WORKLOAD \
  --monitoring=SYSTEM

echo "[Task 4/5] Complete"
echo ""

echo "[Task 5/5] Deploying application from jumphost"

gcloud compute ssh orca-jumphost --zone=$ZONE --quiet --command="
sudo apt-get update -qq
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin -qq
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials $CLUSTER_NAME --internal-ip --project=$PROJECT_ID --zone=$ZONE
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
echo 'Application deployed successfully'
"

echo "[Task 5/5] Complete"
echo ""
echo "================================"
echo "All tasks completed successfully"
echo "================================"
