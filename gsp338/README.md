# GSP338: Monitor and Log with Google Cloud Observability: Challenge Lab

## Challenge Scenario

In your new role as Junior Cloud Engineer for Jooli Inc., you're expected to help manage the Cloud infrastructure components and support the video operations team. Common tasks include monitoring resource utilization, analyzing logs, configuring alerts, and reporting on any issues related to Jooli Inc.'s online services.

As you're expected to have the skills and knowledge for these tasks, step-by-step guides are not provided.

**Jooli Inc. standards you should follow:**
* Create all resources in the <filled in at lab start> region and <filled in at lab start> zone, unless otherwise directed.
* Naming is team-resource, e.g. an instance could be named `video-webserver1`.
* Allocate cost effective resource sizes. Unless directed, use `e2-medium`.

## Your Challenge

Your primary concern is a media upload function. Your tasks today will use **Cloud Operations** tools to improve the company's ability to identify rapid changes in user behavior (demand for 4K/8K video) that might impact performance or cost.

---

### Task 1. Configure Cloud Monitoring

Your first task is to **enable Cloud Monitoring** for your project. A basic dashboard, `Media_Dashboard`, will be made available automatically once enabled.

* Click **Check my progress** to verify the objective.

### Task 2. Configure a Compute Instance to generate Custom Cloud Monitoring metrics

Confirm the monitoring service checking the video processing queue length is working. The service creates the custom metric: `opencensus/my.videoservice.org/measure/input_queue_size`.

You must modify the **startup script** for the `video-queue-monitor` Compute Instance and restart it, so the Go application in `/work/go` can create and write to custom metrics.

**Hints (Tip 1, 2, 3):**
* The startup script is in the Compute Instance metadata key called `startup_script`.
* The Go application requires environment variables (`Google Cloud project`, `instance ID`, and `compute engine zone`). You must configure these in the startup script using `gcloud` and metadata queries.
* The final metric name is `custom.googleapis.com/opencensus/my.videoservice.org/measure/input_queue_size`.

* Click **Check my progress** to verify the objective.

### Task 3. Create a custom metric using Cloud Operations logging events

Create a custom log based metric called **Custom Metric Name** to monitor the rate of high resolution video uploads (4K or 8K).

The Cloud Function logs contain the string `"file_format: 4K"` or `"file_format: 8K"` in the `textPayload` field for high resolution videos.

**Hint (Tip 4, 5):**
* The easiest filter to use is the advanced filter query: `textPayload=~"file_format\: ([4,8]K).*"`
* The metric name must be **Custom Metric Name**.

* Click **Check my progress** to verify the objective.

### Task 4. Add custom metrics to the Media Dashboard in Cloud Operations Monitoring

Add two charts to the **Media_Dashboard**:
1.  A chart for the **video input queue length** custom metric (`input_queue_size`).
2.  A chart for the **high resolution video upload rate** custom log based metric (**Custom Metric Name**).

* Click **Check my progress** to verify the objective.

### Task 5. Create a Cloud Operations alert based on the rate of high resolution video file uploads

Create a custom alert using the high resolution video upload metric (**Custom Metric Name**) that triggers when the upload rate for large videos exceeds a count of **Threshold per second**.

* Click **Check my progress** to verify the objective.

---

### Tips and tricks (Consolidated)

* The startup script for the Compute Instance is in the Compute Instance metadata key called `startup_script`.
* The Compute Instance must have the Cloud Monitoring agent installed and the Go application requires environment variables to be configured with the Google Cloud project, the instance ID, and the compute engine zone.
* The Video Queue length monitoring Go application writes the queue length metric data to a metric called `custom.googleapis.com/opencensus/my.videoservice.org/measure/input_queue_size` associated with the `gce_instance` resource type.
* To create the custom log based metric, the easiest filter to use is the advanced filter query `textPayload=~"file_format\: ([4,8]K).*"`
* You must use the name provided for the custom log based metric that monitors the rate at which high resolution videos are processed: **Custom Metric Name**.