variable "project_id" {
  type        = string
  default     = "still-tower-474715-c6"
  description = "Google Cloud Project Name"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Default region to create resources in"
}

variable "environments" {
  type        = set(string)
  default     = ["stage", "prod"]
  description = "Environments for the project"
}

variable "tenants" {
  type        = set(string)
  default     = ["company1", "company2"]
  description = "Customer environments to setup"
}

variable "gar_image_base" {
  type        = string
  default     = "us-central1-docker.pkg.dev/still-tower-474715-c6/markdown-converter"
  description = "Google Aritifact Registry image base"
}

variable "md-website-port" {
  type        = number
  default     = 5000
  description = "Port for md-website Flask application to bind to"
}

variable "run_gcs_mountpoint" {
  type        = string
  default     = "/mnt/bucket"
  description = "Mountpoint of GCS bucket inside each cloud run container"
}

variable "md-converter-source-dir" {
  type        = string
  default     = "../md-converter"
  description = "Relative source directory for the md-converter code"
}
