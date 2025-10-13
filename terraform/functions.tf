# IAM role


# GCS Source Artifact
resource "google_storage_bucket" "md-converter-artifact" {
  name          = "mdconversions-source-artifact"
  location      = "US"
  force_destroy = true

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

data "archive_file" "md-converter-artifact" {
  type = "zip"

  source_dir  = var.md-converter-source-dir
  output_path = "${var.md-converter-source-dir}/index.zip"
}

resource "google_storage_bucket_object" "md-converter-artifact" {
  name   = "index.zip"
  bucket = google_storage_bucket.md-converter-artifact.name
  source = data.archive_file.md-converter-artifact.output_path
}

# Cloud Function
resource "google_cloudfunctions2_function" "md-converter" {
  name        = "md-converter"
  location    = var.region
  description = "Converts markdown in pubsub messages to html and uploads to GCS"

  build_config {
    runtime     = "python312"
    entry_point = "pubsub_trigger"
    source {
      storage_source {
        bucket = google_storage_bucket.md-converter-artifact.name
        object = google_storage_bucket_object.md-converter-artifact.name
      }
    }

  }

  service_config {
    min_instance_count = 0
    max_instance_count = 1
    available_cpu      = "1"
    available_memory   = "256M"
    timeout_seconds    = 30
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.mdconversions.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}
