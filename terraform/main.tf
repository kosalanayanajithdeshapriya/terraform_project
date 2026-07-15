terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.39.0"
    }
  }

  backend "gcs" {
    bucket = "devops-501908-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "devops-501908"
  region  = var.region
}

data "google_client_config" "default" {

}

module "api" {
  source         = "./modules/api"
  region         = var.region
  repository_url = "${google_artifact_registry_repository.registry.location}-docker.pkg.dev/${google_artifact_registry_repository.registry.project}/${google_artifact_registry_repository.registry.repository_id}"
  access_token   = data.google_client_config.default.access_token
}

moved {
  from = google_cloud_run_v2_service.default
  to   = module.api.google_cloud_run_v2_service.default
}
