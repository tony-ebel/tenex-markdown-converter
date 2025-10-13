################################################
# IAM Service Accounts and Permission Bindings #
################################################
resource "google_service_account" "md-website" {
  for_each = local.tenant_envs

  account_id   = "sa-cloudrun-${each.key}"
  display_name = "SA for Cloud Run Service: ${each.key}"
}

resource "google_project_iam_member" "gar-reader" {
  for_each = local.tenant_envs

  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.md-website[each.key].email}"
}

resource "google_project_iam_member" "secret-reader" {
  for_each = local.tenant_envs

  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.md-website[each.key].email}"
}

resource "google_pubsub_topic_iam_member" "pubsub-publisher" {
  for_each = local.tenant_envs

  topic   = google_pubsub_topic.mdconversions.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.md-website[each.key].email}"
}

resource "google_storage_bucket_iam_member" "gcs-reader" {
  for_each = local.tenant_envs

  bucket = google_storage_bucket.mdconversions[each.key].name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.md-website[each.key].email}"
}


######################
# Cloud Run Services #
######################
resource "google_cloud_run_v2_service" "md-website" {
  for_each = local.tenant_envs

  name                = "mdwebsite-${each.key}"
  location            = "us-central1"
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  scaling {
    min_instance_count = local.cloud_run_settings[each.value.env].min_instances
    max_instance_count = local.cloud_run_settings[each.value.env].max_instances
  }

  template {
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    service_account       = google_service_account.md-website[each.key].email

    containers {
      name  = "md-website"
      image = "${var.gar_image_base}/md-website:${local.cloud_run_settings[each.value.env].tag}"

      ports {
        container_port = var.md-website-port
      }

      resources {
        cpu_idle          = local.cloud_run_settings[each.value.env].cpu_idle
        startup_cpu_boost = true
        limits = {
          cpu    = local.cloud_run_settings[each.value.env].cpu
          memory = local.cloud_run_settings[each.value.env].mem
        }
      }

      startup_probe {
        timeout_seconds   = 60
        period_seconds    = 60
        failure_threshold = 1
        tcp_socket {
          port = var.md-website-port
        }
      }

      liveness_probe {
        initial_delay_seconds = 30
        timeout_seconds       = 1
        period_seconds        = 300
        failure_threshold     = 3
        http_get {
          path = "/health"
          port = var.md-website-port
        }
      }

      env {
        name  = "GCS_MOUNTPOINT"
        value = var.run_gcs_mountpoint
      }

      env {
        name  = "ENVIRONMENT"
        value = each.value.env
      }

      env {
        name  = "BUCKETNAME"
        value = google_storage_bucket.mdconversions[each.key].name
      }

      env {
        name = "SECRETSAUCE"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.secret-sauce[each.value.tenant].secret_id
            version = "latest"
          }
        }
      }

      volume_mounts {
        name       = "bucket"
        mount_path = var.run_gcs_mountpoint
      }
    }

    volumes {
      name = "bucket"
      gcs {
        bucket    = google_storage_bucket.mdconversions[each.key].name
        read_only = true
      }
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
    ]
  }
}

# Allow unathenticated requests to Cloud Run Services
data "google_iam_policy" "md-website-no-auth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "md-website-no-auth" {
  for_each = local.tenant_envs

  location = google_cloud_run_v2_service.md-website[each.key].location
  project  = google_cloud_run_v2_service.md-website[each.key].project
  service  = google_cloud_run_v2_service.md-website[each.key].name

  policy_data = data.google_iam_policy.md-website-no-auth.policy_data
}


######################
# Metrics and Alerts #
######################
resource "google_logging_metric" "md-website-500s" {
  for_each = local.tenant_envs

  name   = "mdwebsite-${each.key}-500s"
  filter = <<-EOT
    resource.type = "cloud_run_revision"
      AND resource.labels.service_name = "mdwebsite-${each.key}"
      AND log_name = "projects/${var.project_id}/logs/run.googleapis.com%2Frequests"
      AND httpRequest.status >= 500
  EOT

  metric_descriptor {
    display_name = "mdwebsite-${each.key} 500s"
    metric_kind  = "DELTA"
    value_type   = "INT64"
  }
}

resource "google_monitoring_alert_policy" "md-website" {
  for_each = local.tenant_envs

  display_name          = "Cloud Run: mdwebsite-${each.key}"
  enabled               = true
  combiner              = "OR"
  severity              = "WARNING"

  documentation {
    subject   = "Cloud Run: mdwebsite-${each.key} alert"
    mime_type = "text/markdown"
    content   = <<-EOT
      Remediation is dependent on the condition that triggered the alert:

      ### Max Instances
      This alert is only to help monitor the current `max_instances` setting.
      Currently the service mdwebsite-${each.key} has `max_instances` set to ${local.cloud_run_settings[each.value.env].max_instances}.
      Might be worth bumping that up if this alert fires often.

      ### HTTP 500s
      This alert fires when the Cloud Run Service is returning many HTTP 500 status codes.
      Currently the alert will fire if the service returns `${local.cloud_run_settings[each.value.env].http_error_threshold}` errors in a 5 minute span.
      This can indicate issues with the service or a dependency.
    EOT
  }

  alert_strategy {
    auto_close = "604800s"
  }

  conditions {
    display_name = "Cloud Run: mdwebsite-${each.key} max_instances"

    condition_threshold {
      filter = <<-EOT
        resource.type = "cloud_run_revision"
          AND resource.labels.service_name = "mdwebsite-${each.key}"
          AND metric.type = "run.googleapis.com/container/instance_count"
          AND metric.labels.state = "active"
      EOT

      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_MEAN"
      }

      comparison = "COMPARISON_GT"
      duration   = local.cloud_run_settings[each.value.env].max_instances_duration

      trigger {
        count = 1
      }

      threshold_value = local.cloud_run_settings[each.value.env].max_instances - 1
    }
  }

  conditions {
    display_name = "Cloud Run: mdwebsite-${each.key} HTTP 500s"

    condition_threshold {
      filter = <<-EOT
        resource.type = "cloud_run_revision"
        AND metric.type = "logging.googleapis.com/user/${google_logging_metric.md-website-500s[each.key].id}"
      EOT

      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_NONE"
        per_series_aligner   = "ALIGN_SUM"
      }

      comparison = "COMPARISON_GT"
      duration   = "300s"

      trigger {
        count = 1
      }

      threshold_value = local.cloud_run_settings[each.value.env].http_error_threshold
    }
  }
}
