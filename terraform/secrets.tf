resource "google_secret_manager_secret" "secret-sauce" {
  for_each = var.tenants

  secret_id = "${each.key}-secret-sauce"

  deletion_protection = true

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}
