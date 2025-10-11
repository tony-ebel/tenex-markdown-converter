output "run_gcs_mountpoint" {
  description = "Mountpoint of GCS bucket inside each cloud run container"
  value       = var.run_gcs_mountpoint
}

output "pubsub_topic" {
  description = "PubSub topic name"
  value       = resource.google_pubsub_topic.mdconversions.name
}
