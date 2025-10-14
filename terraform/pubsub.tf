resource "google_pubsub_topic" "mdconversions" {
  for_each = var.environments

  name = "mdconversions-${each.key}"

  message_retention_duration = "86600s"
}
