terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.39.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = "devops-501908"
  region  = var.region
}

data "google_client_config" "default" {

}

provider "docker" {
  registry_auth {
    address  = "${var.region}-docker.pkg.dev"
    username = "oauth2accesstoken"
    password = data.google_client_config.default.access_token
  }
}
