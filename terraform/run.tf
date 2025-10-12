# IAM Service Accounts and Permission Bindings
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

# Cloud Run Services
resource "google_cloud_run_v2_service" "md-website" {
  for_each = local.tenant_envs

  name                = "mdwebsite-${each.key}"
  location            = "us-central1"
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
    service_account       = google_service_account.md-website[each.key].email

    containers {
      name  = "md-website"
      image = "${var.gar_image_base}/md-website:${local.cloud_run_settings[each.value.env].tag}"

      ports {
        container_port = 5000
      }

      resources {
        cpu_idle          = local.cloud_run_settings[each.value.env].cpu_idle
        startup_cpu_boost = true
        limits = {
          cpu    = local.cloud_run_settings[each.value.env].cpu
          memory = local.cloud_run_settings[each.value.env].mem
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

    scaling {
      min_instance_count = local.cloud_run_settings[each.value.env].min_instances
      max_instance_count = local.cloud_run_settings[each.value.env].max_instances
    }
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
