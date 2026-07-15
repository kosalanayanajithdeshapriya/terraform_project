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
  GitHub Actions ──build/push──▶  Docker image ──▶  Cloud Run service (public)
     (WIF auth)      (docker CLI                          │
                    via local-exec)                        ▼
                                            google_cloud_run_v2_service_iam_member
                                                 (roles/run.invoker → allUsers)

  google_storage_bucket "static-site"  (public website bucket)
  google_storage_bucket_object          (holds the Cloud Run URL)
```

- **`terraform/`** — root module: provider config, GCS remote state backend, the Artifact Registry repository, the static-site storage bucket, and the `api` module call. Also defines the `url` output (the live Cloud Run URL).
- **`terraform/modules/api/`** — builds the Flask app's Docker image, pushes it to Artifact Registry, and deploys it to Cloud Run with public (`allUsers`) invoker access.
- **`src/`** — the Flask app itself: an HTML UI (`templates/`, `static/`) plus a `/api/info` JSON endpoint, served with `gunicorn` via the included `Dockerfile`.

### Why the image build uses `local-exec` instead of the Docker provider

The `kreuzwerker/docker` provider's own build resource (`docker_image`) worked locally but consistently failed in GitHub Actions CI with `invalid reference format` — a provider-specific bug in its legacy build path, not a config issue (verified with an isolated repro). `modules/api/module.tf` instead uses a `null_resource` whose `local-exec` provisioner runs `docker login` / `docker build` / `docker push` directly. This also sidesteps a Windows-specific gotcha: plain `bash` on `PATH` can resolve to the legacy WSL launcher stub instead of Git Bash, so the interpreter is pinned explicitly with a Linux fallback for CI.

## State

Terraform state is stored remotely in a versioned GCS bucket (`gs://devops-501908-tfstate`), not locally — this is required for CI to plan/apply safely and keeps state out of git.

## CI/CD (`.github/workflows/terraform.yml`)

| Trigger | Jobs |
|---|---|
| Pull request touching `terraform/**`, `src/**`, or the workflow file | `terraform fmt -check`, `terraform validate`, `terraform plan` (posted as a PR comment) |
| Push/merge to `chore/ci-remote-state-and-hygiene` (default branch) | `terraform apply` (auto-approved, gated by the `production` GitHub Environment) |

Both triggers watch `src/**` as well as `terraform/**` — the deployed image is built from `src/`, so app-only changes need to trigger a redeploy too, not just infra changes.

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

Requires:
- `gcloud auth application-default login` (or equivalent credentials) with access to the `devops-501908` project
- A local Docker daemon for the image build
- On Windows: Git Bash installed (used explicitly by the build's `local-exec` step to avoid the WSL-launcher-stub conflict)
