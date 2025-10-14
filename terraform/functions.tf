# IAM Service Account
resource "google_service_account" "md-converter" {
  for_each = var.environments

  account_id   = "sa-cf-md-converter-${each.key}"
  display_name = "SA for Cloud Function md-converter ${each.key}"
}

resource "google_storage_bucket_iam_member" "md-converter-gcs-reader" {
  for_each = local.tenant_envs

  bucket = google_storage_bucket.mdconversions[each.key].name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.md-converter[each.value.env].email}"
}

# GCS Source Artifact
resource "google_storage_bucket" "md-converter-artifact" {
  for_each = var.environments

  name          = "mdconversions-${each.key}-source-artifact"
  location      = "US"
  force_destroy = true

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

data "google_storage_bucket_object" "md-converter-artifact" {
  for_each = var.environments

  name   = "index.zip"
  bucket = google_storage_bucket.md-converter-artifact[each.key].name
}

# Cloud Function
resource "google_cloudfunctions2_function" "md-converter" {
  for_each = var.environments

  name        = "md-converter-${each.key}"
  location    = var.region
  description = "Converts markdown in pubsub messages to html and uploads to GCS"

  build_config {
    runtime     = "python312"
    entry_point = "pubsub_trigger"
    source {
      storage_source {
        bucket = google_storage_bucket.md-converter-artifact[each.key].name
        object = data.google_storage_bucket_object.md-converter-artifact[each.key].name
      }
    }

  }

  service_config {
    min_instance_count    = local.cloud_function_settings[each.key].min_instances
    max_instance_count    = local.cloud_function_settings[each.key].max_instances
    available_cpu         = local.cloud_function_settings[each.key].cpu
    available_memory      = local.cloud_function_settings[each.key].mem
    timeout_seconds       = local.cloud_function_settings[each.key].timeout
    service_account_email = google_service_account.md-converter[each.key].email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.mdconversions[each.key].id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}
