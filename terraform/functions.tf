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
