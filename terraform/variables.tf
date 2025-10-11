variable "project_id" {
  type        = string
  default     = "still-tower-474715-c6"
  description = "Google Cloud Project Name"
}

variable "environments" {
  type        = list(string)
  default     = ["stage", "prod"]
  description = "Environments for the project"
}

variable "tenants" {
  type        = list(string)
  default     = ["company1", "company2"]
  description = "Customer environments to setup"
}

variable "gar_image_base" {
  type        = string
  default     = "us-central1-docker.pkg.dev/still-tower-474715-c6/markdown-converter"
  description = "Google Aritifact Registry image base"
}

variable "run_gcs_mountpoint" {
  type        = string
  default     = "/mnt/bucket"
  description = "Mountpoint of GCS bucket inside each cloud run container"
}
