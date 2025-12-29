terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file("C:/Users/w312/devops-gcp-project/terraform/terraform-key.json")
  project     = var.project_id
  region      = var.region
}