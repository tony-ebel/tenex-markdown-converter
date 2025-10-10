resource "google_storage_bucket" "tenex-md-converstions" {
  for_each = local.tenet_envs

  name          = "mdconversions-${each.key}"
  location      = "US"
  force_destroy = true

  storage_class               = "standard"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}
