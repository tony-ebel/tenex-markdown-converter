provider "google" {
  project = var.project_id
}

terraform {
  required_version = "1.6.0" # tofu version
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.30.0"
    }
  }
  backend "gcs" {
    bucket = "tenex-md-convert-terraform"
  }
}
