# terraform_project

A small Flask app deployed to Google Cloud Run, built with Terraform and shipped through a GitHub Actions pipeline.

## What it deploys

```
                    ┌─────────────────────────┐
                    │   Artifact Registry      │
                    │   (docker repo: tf-demo) │
                    └────────────┬─────────────┘
                                 │ image push
                                 ▼
  GitHub Actions ──build──▶  Docker image ──▶  Cloud Run service (public)
     (WIF auth)                                       │
                                                        ▼
                                            google_cloud_run_v2_service_iam_member
                                                 (roles/run.invoker → allUsers)

  google_storage_bucket "static-site"  (public website bucket)
  google_storage_bucket_object          (holds the Cloud Run URL)
```

- **`terraform/`** — root module: provider config, GCS remote state backend, the Artifact Registry repository, the static-site storage bucket, and the `api` module call.
- **`terraform/modules/api/`** — builds the Flask app's Docker image, pushes it to Artifact Registry, and deploys it to Cloud Run with public (`allUsers`) invoker access.
- **`src/`** — the Flask app itself (`gunicorn` + `Dockerfile`).

## State

Terraform state is stored remotely in a versioned GCS bucket (`gs://devops-501908-tfstate`), not locally — this is required for CI to plan/apply safely and keeps state out of git.

## CI/CD (`.github/workflows/terraform.yml`)

| Trigger | Jobs |
|---|---|
| Pull request touching `terraform/**` | `terraform fmt -check`, `terraform validate`, `terraform plan` (posted as a PR comment) |
| Push/merge to `main` | `terraform apply` (auto-approved, gated by the `production` GitHub Environment) |

Authentication to GCP uses **Workload Identity Federation** — no service account keys are stored anywhere. The workflow exchanges GitHub's OIDC token for short-lived GCP credentials, scoped to a dedicated `tf-deployer` service account that can only be impersonated by workflows running in this exact repository.

### One-time manual setup (already done for this repo)

- GCS state bucket: `gs://devops-501908-tfstate` (versioning enabled)
- Service account: `tf-deployer@devops-501908.iam.gserviceaccount.com` (`roles/run.admin`, `roles/artifactregistry.admin`, `roles/storage.admin`, `roles/iam.serviceAccountUser`)
- Workload Identity Pool/Provider: `github-pool` / `github-provider`, restricted to `kosalanayanajithdeshapriya/terraform_project`
- A `production` [GitHub Environment](../../settings/environments) should be configured with required reviewers if you want manual approval before `apply` runs on merge.

## Running locally

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Requires `gcloud auth application-default login` (or equivalent credentials) with access to the `devops-501908` project, plus a local Docker daemon for the image build.
