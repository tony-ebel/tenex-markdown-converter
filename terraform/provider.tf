provider "google" {
  project = var.project_id
  region  = var.region

  add_terraform_attribution_label = false
}

terraform {
  required_version = "1.6.0" # tofu version
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7.1"
    }
  }
  backend "gcs" {
    bucket = "tenex-md-convert-terraform"
  }
}
