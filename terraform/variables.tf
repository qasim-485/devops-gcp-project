variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "GKE Cluster Name"
  type        = string
  default     = "devops-gke-cluster"
}

variable "jenkins_machine_type" {
  description = "Jenkins VM machine type"
  type        = string
  default     = "e2-medium"
}

variable "gke_num_nodes" {
  description = "Number of GKE nodes per zone"
  type        = number
  default     = 2
}