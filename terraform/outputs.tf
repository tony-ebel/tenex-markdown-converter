output "run_gcs_mountpoint" {
  description = "Mountpoint of GCS bucket inside each cloud run container"
  value       = var.run_gcs_mountpoint
}

output "pubsub_topic_stage" {
  description = "PubSub topic name stage"
  value       = google_pubsub_topic.mdconversions["stage"].id
}

output "pubsub_topic_prod" {
  description = "PubSub topic name prod"
  value       = google_pubsub_topic.mdconversions["prod"].id
}

output "function_sa_stage" {
  description = "Cloud Run Function service account for stage environment"
  value = google_service_account.md-converter["stage"].email
}

output "function_sa_prod" {
  description = "Cloud Run Function service account for prod environment"
  value = google_service_account.md-converter["prod"].email
}

output "run_services_stage" {
  description = "Cloud Run Services in stage environment"
  value = join(",", [
    for key, value in local.tenant_envs : key
    if value.env == "stage"
  ])
}

output "run_services_prod" {
  description = "Cloud Run Services in prod environment"
  value = join(",", [
    for key, value in local.tenant_envs : key
    if value.env == "prod"
  ])
}
