# GSP342: Implement Cloud Security Fundamentals on Google Cloud: Challenge Lab

## Challenge Scenario

You are a junior member of the security team for the Orca team in Jooli Inc., responsible for securing the Cloud infrastructure. You must deploy, configure, and test a new Kubernetes Engine cluster according to the organization's security standards.

**Security Requirements:**
* Cluster must use a dedicated service account with least required privileges.
* Cluster must be a **private cluster** with the public endpoint disabled.
* Master authorized network must include only the IP address of the Orca group's management jumphost.
* Cluster must be deployed to the `orca-build-subnet` in the `Orca Build VPC`.
* All new services must include the "**orca-**" prefix.

**Required Built-in Service Account Roles:**
* `roles/monitoring.viewer`
* `roles/monitoring.metricWriter`
* `roles/logging.logWriter`

---

## Task 1. Create a custom security role

Create a new custom IAM security role called **Custom Securiy Role** to provide Google Cloud Storage bucket and object permissions.

**Permissions required for the custom role:**
* `storage.buckets.get`
* `storage.objects.get`
* `storage.objects.list`
* `storage.objects.update`
* `storage.objects.create`

Check that a **Custom security role** has been created.

---

## Task 2. Create a service account

Create the dedicated service account that will be used for the new private cluster. Name this account **Service Account**.

Check that a **new service account** has been created.

---

## Task 3. Bind a custom security role to a service account

Bind the three required **Cloud Operations** roles (monitoring/logging) and the **Custom IAM role** (storage permissions) to the **Service Account** created earlier.

Check that a the correct built in and custom security roles have been bound to the new service account.

---

## Task 4. Create and configure a new Kubernetes Engine private cluster

Use the configured service account to create a new Kubernetes Engine private cluster.

**Cluster Configuration Details:**
* Cluster name: **Cluster Name** (must use "orca-" prefix)
* Subnet: `orca-build-subnet`
* Service Account: **Service Account**
* Private cluster options must be enabled: `enable-master-authorized-networks`, `enable-ip-alias`, `enable-private-nodes`, and `enable-private-endpoint`.
* **Master Authorized Network:** Must include the internal IP address of the `orca-jumphost` compute instance (use a `/32` netmask).

Confirm that a **Kubernetes Engine private cluster** has been deployed correctly.

---

## Task 5. Deploy an application to a private Kubernetes Engine cluster

Configure the environment using the `orca-jumphost` to deploy a simple test application to the new cluster.

**Deployment Command:**
    kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0

**Note:** Ensure you install the `gke-gcloud-auth-plugin` before running `kubectl`.

Check that an **application has been deployed** to a private Kubernetes Engine cluster.

---

## Tips and Tricks

* **Tip 1 (Authentication):** Install the `gke-gcloud-auth-plugin` and use the `--internal-ip` flag when retrieving credentials via `gcloud container clusters get-credentials` from the `orca-jumphost`.
* **Tip 2 (Netmask):** When adding the internal IP of the `orca-jumphost` to the master authorized network, use a **/32** netmask.
* **Tip 3 (Private Endpoint):** Since the `enable-private-endpoint` option is used, you must connect via the `orca-jumphost` (or a proxy in the same VPC) to access the cluster's internal management IP address.