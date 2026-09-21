variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo in org/repo format e.g. neediuminc/rag-pipeline"
}

variable "bucket_name" {
  type        = string
  description = "GCS bucket for PDFs — created by bootstrap.ps1"
}

variable "corpus_resource_name" {
  type        = string
  description = "Full Vertex RAG corpus name — output of bootstrap"
}

variable "allowed_domain" {
  type        = string
  description = "Workspace domain granted access e.g. neediuminc.com"
}

variable "generation_model" {
  type    = string
  default = "gemini-3.8-flash"
}

variable "iap_client_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "iap_client_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "enable_iap" {
  type        = bool
  default     = false
  description = "Set to true after OAuth client is created and Cloud Run is deployed"
}
