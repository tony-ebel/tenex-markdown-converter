output "run_gcs_mountpoint" {
  description = "Mountpoint of GCS bucket inside each cloud run container"
  value       = var.run_gcs_mountpoint
}

output "pubsub_stage_topic" {
  description = "PubSub topic name stage"
  value       = google_pubsub_topic.mdconversions["stage"].name
}

output "pubsub_prod_topic" {
  description = "PubSub topic name prod"
  value       = google_pubsub_topic.mdconversions["prod"].name
}

output "run_stage_services" {
  description = "Cloud Run Services in stage environment"
  value = join(",", [
    for key, value in local.tenant_envs : key
    if value.env == "stage"
  ])
}

output "run_prod_services" {
  description = "Cloud Run Services in prod environment"
  value = join(",", [
    for key, value in local.tenant_envs : key
    if value.env == "prod"
  ])
}

output "function_stage" {
  description = "Cloud Function Service for stage environment"
  value = google_cloudfunctions2_function.md-converter["stage"].name
}

output "function_prod" {
  description = "Cloud Function Service for prod environment"
  value = google_cloudfunctions2_function.md-converter["prod"].name
}
