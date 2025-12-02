# Google Cloud Labs

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Shell](https://img.shields.io/badge/shell-bash-green.svg)
![GCP](https://img.shields.io/badge/platform-Google%20Cloud-4285F4.svg)
![Labs](https://img.shields.io/badge/labs-5-orange.svg)

![Google Cloud Labs Screenshot](img/screenshot.png)

Automation scripts for Google Cloud Skills Boost Challenge Labs.

## Overview

Automation scripts for Google Cloud Skills Boost Challenge Labs. Each script prompts for the lab-specific variables, validates input, and executes the required gcloud commands in sequence. The goal is to reduce repetitive setup work while keeping the process transparent.

Every script follows the same pattern:
1. Prompt for lab variables (with validation)
2. Enable required APIs if needed
3. Execute tasks with progress logging
4. Output results at each step

## Available Labs

| Code | Lab | What It Covers |
|------|-----|----------------|
| [GSP327](gsp327/) | Engineer Data for Predictive Modeling with BigQuery ML | Building ML models for taxi fare prediction using BigQuery ML and feature engineering |
| [GSP338](gsp338/) | Monitor and Log with Google Cloud Observability | Setting up custom metrics, log-based metrics, and alerts for monitoring services |
| [GSP341](gsp341/) | Create ML Models with BigQuery ML | Creating classification models to predict customer behavior using logistic regression |
| [GSP342](gsp342/) | Implement Cloud Security Fundamentals | Building secure GKE private clusters with custom IAM roles and service accounts |
| [GSP345](gsp345/) | Build Infrastructure with Terraform | Managing GCP infrastructure as code with Terraform modules and remote state |

## How to Use

Pick whichever method works for you:

**Clone and Run Locally**
```bash
git clone https://github.com/dapovoa/gcp-labs.git
cd gcp-labs/gsp327
bash solution.sh
```

**Quick One-Liner**
```bash
curl -L https://raw.githubusercontent.com/dapovoa/gcp-labs/main/gsp327/solution.sh -o solution.sh && chmod +x solution.sh && ./solution.sh
```

**Run Without Saving**
```bash
bash <(curl -s https://raw.githubusercontent.com/dapovoa/gcp-labs/main/gsp327/solution.sh)
```

## Repository Structure

```
gcp-labs/
  gsp327/
    README.md
    solution.sh
  gsp338/
    README.md
    solution.sh
  gsp341/
    README.md
    solution.sh
  gsp342/
    README.md
    solution.sh
  gsp345/
    README.md
    solution.sh
```

## Before You Run Anything

Make sure you have:
- An active GCP project (obviously)
- gcloud CLI installed and authenticated
- The right IAM permissions for whatever resources the lab creates
- The lab instructions open so you can grab the variable names

The scripts will tell you if APIs need to be enabled. Some will do it automatically, others will prompt you.

## Features

All scripts follow the same pattern: standardized input prompts, task progress tracking, verbose logging, and input validation. Once you've used one, you know how they all work.

## Tech Stack

The scripts use standard GCP services:
- BigQuery and BigQuery ML for data and machine learning labs
- GKE for container and security labs
- Cloud Monitoring and Logging for observability
- Terraform for infrastructure as code
- Standard bash scripting, nothing fancy

## Fair Warning

These scripts create real GCP resources. That means:
- You might incur costs (usually minimal for lab environments)
- Resources will exist in your project until you clean them up
- Always review what's being created before you run anything
- These are for learning, not production use

## License

This project is under the MIT License. See the [LICENSE](LICENSE) file for details.
