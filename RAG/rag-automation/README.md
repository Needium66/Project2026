####
To automate the deployment of rag.
# RAG Pipeline — GitHub Actions → GCP

Push to `main` → GitHub Actions provisions infrastructure (Terraform),
builds and deploys the Gradio UI (Cloud Run + IAP), and syncs documents
into the Vertex AI RAG corpus. No manual GCP console steps after first setup.

## Repository layout

```
terraform/          Infrastructure as code (APIs, IAM, WIF, Secrets, Cloud Run, IAP)
app/                Gradio UI (main.py, Dockerfile, requirements.txt)
scripts/            import_files.py — corpus sync, called by CI
docs/               Drop PDFs/markdown here → git push → auto-imported to corpus
.github/workflows/  deploy.yml — 4-job pipeline
```

## One-time local setup (run these once from your terminal)

### 1. Create Terraform state bucket
```powershell
gcloud storage buckets create gs://YOUR_PROJECT_ID-tfstate --location=us-central1
```
Then update `terraform/versions.tf` → `bucket = "YOUR_PROJECT_ID-tfstate"`

### 2. Fill in Terraform variables
```powershell
copy terraform\terraform.tfvars.example terraform\terraform.tfvars
# Edit terraform.tfvars with your real values — never commit this file
```

### 3. First Terraform apply (local — creates WIF so CI can take over after this)
```powershell
cd terraform
terraform init
terraform apply
```
Note the outputs — you need `wif_provider` and `github_deployer_sa` for GitHub.

### 4. Set GitHub repository secrets and variables
Go to: Settings → Secrets and variables → Actions

**Secrets** (sensitive):
| Name               | Value                                    |
|--------------------|------------------------------------------|
| WIF_PROVIDER       | from `terraform output wif_provider`     |
| WIF_SERVICE_ACCOUNT| from `terraform output github_deployer_sa`|
| RAG_CORPUS         | full corpus resource name                |
| IAP_CLIENT_ID      | OAuth client ID                          |
| IAP_CLIENT_SECRET  | OAuth client secret                      |

**Variables** (non-sensitive):
| Name          | Value                    |
|---------------|--------------------------|
| GCP_PROJECT   | your-project-id          |
| GITHUB_REPO   | your-org/rag-pipeline    |
| BUCKET_NAME   | rag            |
| ALLOWED_DOMAIN| inc.com           |

### 5. Push to GitHub
```powershell
git init
git add .
git commit -m "Initial RAG pipeline"
git remote add origin https://github.com/YOUR_ORG/rag-pipeline.git
git push -u origin main
```
The Actions workflow triggers automatically. Watch it at:
`https://github.com/YOUR_ORG/rag-pipeline/actions`

## Adding documents (ongoing)

Drop files into `docs/` and push:
```powershell
copy .\new-notes.pdf docs\
git add docs/new-notes.pdf
git commit -m "Add new notes"
git push
```
The `sync-corpus` job detects the change, uploads to GCS, and imports into
the corpus automatically. No manual steps.

## Updating the UI (ongoing)

Edit `app/main.py` and push — the `build` and `deploy` jobs handle the rest.

## Manual corpus sync (if needed)
```powershell
python scripts/import_files.py `
  --project YOUR_PROJECT_ID `
  --corpus  "projects/.../ragCorpora/..." `
  --bucket  gs://needium66_rag/notes/
```
