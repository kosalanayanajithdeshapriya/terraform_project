resource "docker_image" "terraform_demo" {
  name = local.docker_image-url
  build {
    context = "../src/"
    tag     = [local.docker_image-url]

  }
}

resource "google_artifact_registry_repository" "registry" {
  location      = var.region
  repository_id = "tf-demo"
  format        = "DOCKER"

}

resource "docker_registry_image" "demo_image" {
  name          = docker_image.terraform_demo.name
  keep_remotely = true
  depends_on    = [docker_image.terraform_demo, google_artifact_registry_repository.registry]

}

resource "google_cloud_run_v2_service" "default" {
  name     = "tf-cloudrun-demo"
  location = var.region

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
