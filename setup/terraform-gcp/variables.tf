variable "project" {
  description = "GCP project unique ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "allowed_ip_ranges" {
  type    = list(string)
  description = "List of IP ranges allowed through the firewall"
}
