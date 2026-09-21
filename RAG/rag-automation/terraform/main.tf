data "google_project" "project" {}

# ── Enable APIs ──────────────────────────────────────────────────────────────
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "iap.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

# ── Artifact Registry ────────────────────────────────────────────────────────
resource "google_artifact_registry_repository" "rag_ui" {
  repository_id = "rag-ui"
  format        = "DOCKER"
  location      = var.region
  depends_on    = [google_project_service.apis]
}

# ── GCS bucket ───────────────────────────────────────────────────────────────
# If bucket already exists, import it first:
#   terraform import google_storage_bucket.rag_docs YOUR_BUCKET_NAME
resource "google_storage_bucket" "rag_docs" {
  name                        = var.bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false
}

# ── Service accounts ─────────────────────────────────────────────────────────
resource "google_service_account" "rag_ui_runtime" {
  account_id   = "rag-ui-runtime"
  display_name = "RAG UI Runtime"
}

resource "google_service_account" "github_deployer" {
  account_id   = "github-deployer"
  display_name = "GitHub Actions Deployer"
}

# ── Runtime SA permissions ───────────────────────────────────────────────────
resource "google_project_iam_member" "runtime_vertex" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.rag_ui_runtime.email}"
}

resource "google_project_iam_member" "runtime_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.rag_ui_runtime.email}"
}

# ── Deployer SA permissions ──────────────────────────────────────────────────
resource "google_project_iam_member" "deployer_run" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_vertex" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

# ── RAG service agent bucket access ─────────────────────────────────────────
resource "google_storage_bucket_iam_member" "rag_agent_viewer" {
  bucket = google_storage_bucket.rag_docs.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-vertex-rag.iam.gserviceaccount.com"
}

# ── Workload Identity Federation ─────────────────────────────────────────────
resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "installsify-pool"
  display_name              = "Installsify Pool"
  depends_on                = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = "installsify-pool"
  workload_identity_pool_provider_id = "github-provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = "assertion.repository == '${var.github_repo}'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_wif" {
  service_account_id = google_service_account.github_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

# ── Secret Manager ───────────────────────────────────────────────────────────
resource "google_secret_manager_secret" "corpus" {
  secret_id  = "rag-corpus-name"
  depends_on = [google_project_service.apis]

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "corpus" {
  secret      = google_secret_manager_secret.corpus.id
  secret_data = var.corpus_resource_name
}

resource "google_secret_manager_secret" "iap_client_id" {
  count      = var.enable_iap ? 1 : 0
  secret_id  = "iap-client-id"
  depends_on = [google_project_service.apis]

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "iap_client_id" {
  count       = var.enable_iap ? 1 : 0
  secret      = google_secret_manager_secret.iap_client_id[0].id
  secret_data = var.iap_client_id
}

resource "google_secret_manager_secret" "iap_client_secret" {
  count      = var.enable_iap ? 1 : 0
  secret_id  = "iap-client-secret"
  depends_on = [google_project_service.apis]

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "iap_client_secret" {
  count       = var.enable_iap ? 1 : 0
  secret      = google_secret_manager_secret.iap_client_secret[0].id
  secret_data = var.iap_client_secret
}

# ── Cloud Run ────────────────────────────────────────────────────────────────
resource "google_cloud_run_v2_service" "rag_ui" {
  name     = "rag-ui"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.rag_ui_runtime.email

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/rag-ui/app:latest"

      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }

      env {
        name  = "GCP_LOCATION"
        value = "global"
      }

      env {
        name  = "GENERATION_MODEL"
        value = var.generation_model
      }

      env {
        name  = "TOP_K"
        value = "5"
      }

      env {
        name = "RAG_CORPUS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.corpus.secret_id
            version = "latest"
          }
        }
      }

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          memory = "512Mi"
          cpu    = "1"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }

  depends_on = [google_artifact_registry_repository.rag_ui]
}

# ── Cloud Run IAM ────────────────────────────────────────────────────────────
# Phase 1 (enable_iap = false): domain invokes directly
resource "google_cloud_run_service_iam_member" "domain_invoker" {
  count    = var.enable_iap ? 0 : 1
  location = var.region
  service  = google_cloud_run_v2_service.rag_ui.name
  role     = "roles/run.invoker"
  member   = "domain:${var.allowed_domain}"
}

# Phase 2 (enable_iap = true): IAP service account invokes
resource "google_cloud_run_service_iam_member" "iap_invoker" {
  count    = var.enable_iap ? 1 : 0
  location = var.region
  service  = google_cloud_run_v2_service.rag_ui.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
}
