output "rag_ui_url" {
  value       = google_cloud_run_v2_service.rag_ui.uri
  description = "Share this URL with internal users"
}

output "wif_provider" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "Paste into GitHub secret: WIF_PROVIDER"
}

output "github_deployer_sa" {
  value       = google_service_account.github_deployer.email
  description = "Paste into GitHub secret: WIF_SERVICE_ACCOUNT"
}

output "artifact_registry_image" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/rag-ui/app"
  description = "Container image base path"
}
