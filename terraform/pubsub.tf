resource "google_pubsub_topic" "mdconversions" {
  name = "mdconversions"

  message_retention_duration = "86600s"
}
