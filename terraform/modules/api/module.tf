terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

locals {
  # On Windows, plain "bash" on PATH can resolve to the legacy WSL launcher
  # stub at C:\Windows\System32\bash.exe instead of Git Bash, which fails
  # with "execvpe(/bin/bash) failed" when no WSL distro is installed. Pin
  # Git Bash explicitly when present; fall back to /bin/sh on Linux CI.
  bash_interpreter = fileexists("C:/Program Files/Git/bin/bash.exe") ? ["C:/Program Files/Git/bin/bash.exe", "-c"] : ["/bin/sh", "-c"]
}

resource "null_resource" "build_and_push" {
  triggers = {
    docker_image_url = local.docker_image-url
  }

  provisioner "local-exec" {
    interpreter = local.bash_interpreter
    environment = {
      REGISTRY_HOST = "${var.region}-docker.pkg.dev"
      IMAGE_URL     = local.docker_image-url
      ACCESS_TOKEN  = var.access_token
    }
    command = <<-EOT
      set -e
      echo "$ACCESS_TOKEN" | docker login -u oauth2accesstoken --password-stdin "https://$REGISTRY_HOST"
      docker build -t "$IMAGE_URL" "../src"
      docker push "$IMAGE_URL"
    EOT
  }
}

resource "google_cloud_run_v2_service" "default" {
  name                = "tf-cloudrun-demo"
  location            = var.region
  deletion_protection = false

  template {
    containers {
      image = local.docker_image-url
    }
  }

  depends_on = [null_resource.build_and_push]
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.default.project
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

