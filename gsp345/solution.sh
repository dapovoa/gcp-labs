#!/bin/bash
set -e

echo "============================================================"
echo "GSP345 - Build Infrastructure with Terraform on Google Cloud"
echo "============================================================"
echo ""

echo "Required variables:"
read -p "  - Project ID: " PROJECT_ID
read -p "  - Bucket Name: " BUCKET_NAME
read -p "  - Instance Name (for the 3rd instance, e.g., tf-instance-xxxx): " INSTANCE_NAME
read -p "  - VPC Name: " VPC_NAME
echo ""

export PROJECT_ID
export BUCKET_NAME
export INSTANCE_NAME
export VPC_NAME

if [ -z "$PROJECT_ID" ] || [ -z "$BUCKET_NAME" ] || [ -z "$INSTANCE_NAME" ] || [ -z "$VPC_NAME" ]; then
    echo "Error: All variables are required"
    exit 1
fi

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

echo "Configuration:"
echo "  - Project: $PROJECT_ID"
echo "  - Bucket: $BUCKET_NAME"
echo "  - Instance: $INSTANCE_NAME"
echo "  - VPC: $VPC_NAME"
echo "  - Region: $REGION"
echo "  - Zone: $ZONE"
echo ""

echo "[Task 1/7] Creating directory structure and configuration files"

mkdir -p modules/instances modules/storage

touch main.tf variables.tf

touch modules/instances/instances.tf modules/instances/outputs.tf modules/instances/variables.tf

touch modules/storage/storage.tf modules/storage/outputs.tf modules/storage/variables.tf

cat > variables.tf <<EOF
variable "region" {
  description = "Main project region"
  type        = string
  default     = "$REGION"
}

variable "zone" {
  description = "Main project zone"
  type        = string
  default     = "$ZONE"
}

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "$PROJECT_ID"
}
EOF

cat > modules/instances/variables.tf <<'EOF'
variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "project_id" {
  type = string
}

variable "vpc_network_name" {
  type    = string
  default = "default"
}

variable "subnet_01_link" {
  type    = string
  default = ""
}

variable "subnet_02_link" {
  type    = string
  default = ""
}
EOF

cat > modules/storage/variables.tf <<'EOF'
variable "bucket_name" {
  description = "Name of the GCS bucket for state"
  type        = string
}
EOF

cat > main.tf <<'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

module "instances" {
  source     = "./modules/instances"
  project_id = var.project_id
  region     = var.region
  zone       = var.zone
}
EOF

terraform init

echo "[Task 1/7] Complete"
echo ""

echo "[Task 2/7] Importing existing instances"

IFS=$'\n' read -r -d '' instance_id_1 instance_id_2 <<< "$(gcloud compute instances list --filter="name:tf-instance" --format="value(id)" | sort)"

if [ -z "$instance_id_1" ] || [ -z "$instance_id_2" ]; then
    echo "Error: Could not find instance IDs for tf-instance-1 or tf-instance-2"
    exit 1
fi

echo "Found Instance IDs:"
echo "  - tf-instance-1: $instance_id_1"
echo "  - tf-instance-2: $instance_id_2"

cat > modules/instances/instances.tf <<'EOF'
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "n1-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.vpc_network_name
    access_config {}
  }

  metadata_startup_script   = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "n1-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.vpc_network_name
    access_config {}
  }

  metadata_startup_script   = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
EOF

terraform import "module.instances.google_compute_instance.tf-instance-1" "$instance_id_1"
terraform import "module.instances.google_compute_instance.tf-instance-2" "$instance_id_2"

terraform apply -auto-approve

echo "[Task 2/7] Complete"
echo ""

echo "[Task 3/7] Configuring remote backend"

cat > modules/storage/storage.tf <<'EOF'
resource "google_storage_bucket" "storage-bucket" {
  name                        = var.bucket_name
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true
}
EOF

cat >> main.tf <<EOF

module "storage" {
  source      = "./modules/storage"
  bucket_name = "$BUCKET_NAME"
}
EOF

terraform init -reconfigure

terraform apply -auto-approve

cat > main.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "$BUCKET_NAME"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

module "instances" {
  source     = "./modules/instances"
  project_id = var.project_id
  region     = var.region
  zone       = var.zone
}

module "storage" {
  source      = "./modules/storage"
  bucket_name = "$BUCKET_NAME"
}
EOF

terraform init -migrate-state -force-copy

echo "[Task 3/7] Complete"
echo ""

echo "[Task 4/7] Modifying infrastructure (adding third instance)"

cat > modules/instances/instances.tf <<EOF
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.vpc_network_name
    access_config {}
  }

  metadata_startup_script   = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.vpc_network_name
    access_config {}
  }

  metadata_startup_script   = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-3" {
  name         = "$INSTANCE_NAME"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.vpc_network_name
    access_config {}
  }

  metadata_startup_script   = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
EOF

terraform apply -auto-approve

echo "[Task 4/7] Complete"
echo ""

echo "[Task 5/7] Destroying third instance"

cat > modules/instances/instances.tf <<'EOF'
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.vpc_network_name
    access_config {}
  }

  metadata_startup_script   = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = var.vpc_network_name
    access_config {}
  }

  metadata_startup_script   = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
EOF

terraform apply -auto-approve

echo "[Task 5/7] Complete"
echo ""

echo "[Task 6/7] Using VPC module from registry (2 phases)"

echo "Phase 1: Creating VPC and subnets"

cat > main.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "$BUCKET_NAME"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "10.0.0"

  project_id   = var.project_id
  network_name = "$VPC_NAME"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = var.region
    },
    {
      subnet_name   = "subnet-02"
      subnet_ip     = "10.10.20.0/24"
      subnet_region = var.region
    }
  ]
}

module "instances" {
  source           = "./modules/instances"
  project_id       = var.project_id
  region           = var.region
  zone             = var.zone
  vpc_network_name = "default"
  subnet_01_link   = ""
  subnet_02_link   = ""
}

module "storage" {
  source      = "./modules/storage"
  bucket_name = "$BUCKET_NAME"
}
EOF

cat > modules/instances/instances.tf <<'EOF'
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
EOF

terraform init -upgrade

terraform apply -auto-approve

echo "Waiting for subnets to be fully ready"
sleep 15

echo "Phase 2: Connecting instances to new VPC"

cat > main.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "$BUCKET_NAME"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "10.0.0"

  project_id   = var.project_id
  network_name = "$VPC_NAME"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = var.region
    },
    {
      subnet_name   = "subnet-02"
      subnet_ip     = "10.10.20.0/24"
      subnet_region = var.region
    }
  ]
}

module "instances" {
  source           = "./modules/instances"
  project_id       = var.project_id
  region           = var.region
  zone             = var.zone
  vpc_network_name = module.vpc.network_name
  subnet_01_link   = module.vpc.subnets_self_links[0]
  subnet_02_link   = module.vpc.subnets_self_links[1]
}

module "storage" {
  source      = "./modules/storage"
  bucket_name = "$BUCKET_NAME"
}
EOF

cat > modules/instances/instances.tf <<'EOF'
resource "google_compute_instance" "tf-instance-1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface {
    network    = var.vpc_network_name
    subnetwork = var.subnet_01_link
    access_config {}
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf-instance-2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface {
    network    = var.vpc_network_name
    subnetwork = var.subnet_02_link
    access_config {}
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
EOF

terraform apply -auto-approve

echo "[Task 6/7] Complete"
echo ""

echo "[Task 7/7] Configuring firewall rule"

cat >> main.tf <<'EOF'

resource "google_compute_firewall" "tf-firewall" {
  name    = "tf-firewall"
  network = module.vpc.network_self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}
EOF

terraform apply -auto-approve

echo "[Task 7/7] Complete"
echo ""
echo "================================"
echo "All tasks completed successfully"
echo "================================"
echo ""
echo "Summary of what was created:"
echo "  - Task 1: Directory structure and configuration files"
echo "  - Task 2: Imported 2 existing instances"
echo "  - Task 3: Remote backend in bucket: $BUCKET_NAME"
echo "  - Task 4: Updated instances to e2-standard-2 and added third instance"
echo "  - Task 5: Removed third instance"
echo "  - Task 6: Created VPC: $VPC_NAME with 2 subnets"
echo "  - Task 7: Created firewall rule allowing TCP:80"
