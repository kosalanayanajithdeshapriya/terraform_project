terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_image" "terraform_demo" {
  name = local.docker_image-url
  build {
    context = "../src/"
    tag     = [local.docker_image-url]

  }
}


resource "docker_registry_image" "demo_image" {
  name          = docker_image.terraform_demo.name
  keep_remotely = true
  depends_on    = [docker_image.terraform_demo]
}

resource "google_cloud_run_v2_service" "default" {
  name                = "tf-cloudrun-demo"
  location            = var.region
  deletion_protection = false

  template {
    containers {
      image = docker_registry_image.demo_image.name
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.default.project
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

