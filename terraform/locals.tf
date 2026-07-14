locals {
  docker_image-url = "${google_artifact_registry_repository.registry.location}-docker.pkg.dev/${google_artifact_registry_repository.registry.project}/${google_artifact_registry_repository.registry.repository_id}/tf-demo:latest:${formatdate("YYYYMMDDhhmmss", timestamp())}"
}
