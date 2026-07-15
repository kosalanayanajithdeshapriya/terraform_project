locals {
  docker_image-url = "${var.repository_url}/tf-demo:${formatdate("YYYYMMDDhhmmss", timestamp())}"
}
