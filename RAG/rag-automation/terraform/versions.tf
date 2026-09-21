terraform {
  required_version = ">= 1.7"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 6.0" }
  }
  # Create this bucket once before `terraform init`:
  # gcloud storage buckets create gs://<project>-tfstate --location=us-central1
  backend "gcs" {
    bucket = ""
    prefix = "rag-pipeline"
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
}
