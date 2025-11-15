# GSP345: Build Infrastructure with Terraform on Google Cloud

## Challenge Scenario

You are a cloud engineer intern tasked with creating and managing infrastructure efficiently using **Terraform** on Google Cloud. You need to import existing instances, create new ones, set up a VPC network, a firewall rule, and configure a remote backend using Cloud Storage.

**Note:** At the end of every section, plan and apply your changes to allow your work to be successfully verified. Maintain correct file path and indentation.

---

## Task 1. Create the configuration files

Create your Terraform configuration files and a directory structure:

    main.tf
    variables.tf
    modules/
    └── instances
        ├── instances.tf
        ├── outputs.tf
        └── variables.tf
    └── storage
        ├── storage.tf
        ├── outputs.tf
        └── variables.tf

**File Content:**
* **variables.tf (root & modules):** Add variables `region`, `zone`, and `project_id`. Use `<filled in at lab start>`, `<filled in at lab start>`, and your Google Cloud Project ID as default values.
* **main.tf:** Add the Terraform block and the Google Provider. Verify the `zone` argument is added along with `project` and `region` arguments in the Google Provider block.

Initialize Terraform.

---

## Task 2. Import infrastructure

Two instances (`tf-instance-1` and `tf-instance-2`) already exist. You must import them into the `instances` module.

**Steps:**
1.  Add the module reference into the `main.tf` file and re-initialize Terraform.
2.  Write resource configurations in `modules/instances/instances.tf` to match the pre-existing instances, named `tf-instance-1` and `tf-instance-2`.
3.  Include the following minimal arguments in the configuration: `machine_type`, `boot_disk`, `network_interface`, `metadata_startup_script`, and `allow_stopping_for_update`.

**Configuration Snippets:**
    metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
    allow_stopping_for_update = true

4.  Use `terraform import` to import the existing instances into your `instances` module.
5.  Apply your changes.

Click **Check my progress** to verify the objective.

---

## Task 3. Configure a remote backend

Create a Cloud Storage bucket resource inside the `storage` module.

**Bucket Configuration:**
* Bucket name: **Bucket Name** (must use the "orca-" prefix).
* `location = "US"`
* `force_destroy = true`
* `uniform_bucket_level_access = true`

**Steps:**
1.  Add the module reference to the `main.tf` file.
2.  Initialize the module and apply the changes to create the bucket.
3.  Configure this storage bucket as the **remote backend** inside the `main.tf` file. Be sure to use the prefix `terraform/state`.
4.  Upon `init`, type **yes** at the prompt to copy the existing state.

Click **Check my progress** to verify the objective.

---

## Task 4. Modify and update infrastructure

Navigate to the `instances` module and modify the resource configurations:

* Modify `tf-instance-1` to use an `e2-standard-2` machine type.
* Modify `tf-instance-2` to use an `e2-standard-2` machine type.
* Add a third instance resource named **Instance Name** (must use "orca-" prefix) using an `e2-standard-2` machine type.

Initialize Terraform and apply your changes.

Click **Check my progress** to verify the objective.

---

## Task 5. Destroy resources

Destroy the third instance **Instance Name** by removing the resource from the configuration file (`modules/instances/instances.tf`).

Initialize Terraform and apply the changes.

Click **Check my progress** to verify the objective.

---

## Task 6. Use a module from the Registry

Use the **Network Module** from the Terraform Registry to create a VPC network.

**Module Configuration in `main.tf`:**
* Use `version = "10.0.0"`.
* Name the VPC **VPC Name** (must use "orca-" prefix) with a global routing mode.
* Specify **2 subnets** in the region.

**Subnet Configurations:**
* **Subnet 1:** Name `subnet-01`, IP `10.10.10.0/24`, Region `<filled in at lab start>`.
* **Subnet 2:** Name `subnet-02`, IP `10.10.20.0/24`, Region `<filled in at lab start>`.

**Steps:**
1.  Initialize Terraform and run an `apply` to create the networks.
2.  Update the instance configurations in `instances.tf`:
    * Set the network argument to **VPC Name**.
    * Set the subnetwork argument for `tf-instance-1` to `subnet-01`.
    * Set the subnetwork argument for `tf-instance-2` to `subnet-02`.

Click **Check my progress** to verify the objective.

---

## Task 7. Configure a firewall

Create a firewall rule resource named `tf-firewall` in the `main.tf` file.

**Firewall Configuration:**
* Permit the **VPC Name** network.
* Allow ingress connections on TCP port **80**.
* Set `source_ranges` argument to **0.0.0.0/0**.

Initialize Terraform and apply your changes.

Click **Check my progress** to verify the objective.