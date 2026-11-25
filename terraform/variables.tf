variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region (use us-central1 for Always Free e2-micro eligibility)"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone within the chosen region"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Compute Engine machine type"
  type        = string
  default     = "e2-micro"
}
variable "alert_email" {
  description = "Email address for Cloud Monitoring alert notifications"
  type        = string
}
