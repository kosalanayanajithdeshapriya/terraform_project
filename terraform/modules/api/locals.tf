locals {
  docker_image-url = "${var.repository_url}/tf-demo:latest:${formatdate("YYYYMMDDhhmmss", timestamp())}"
}
