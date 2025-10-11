resource "google_cloud_run_v2_service" "md-website" {
  for_each = local.tenant_envs

  name                = "mdwebsite-${each.key}"
  location            = "us-central1"
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

    containers {
      name  = "md-website"
      image = "${var.gar_image_base}/md-website:${local.cloud_run_settings[each.value.env].tag}"

      ports {
        container_port = 80
      }

      resources {
        cpu_idle          = local.cloud_run_settings[each.value.env].cpu_idle
        startup_cpu_boost = true
        limits = {
          cpu    = local.cloud_run_settings[each.value.env].cpu
          memory = local.cloud_run_settings[each.value.env].mem
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

    scaling {
      min_instance_count = local.cloud_run_settings[each.value.env].min_instances
      max_instance_count = local.cloud_run_settings[each.value.env].max_instances
    }
  }
}
