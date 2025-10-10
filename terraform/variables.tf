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

variable "tenents" {
  type        = list(string)
  default     = ["company1", "company2"]
  description = "Customer environments to setup"
}
