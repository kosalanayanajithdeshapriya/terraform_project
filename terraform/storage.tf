resource "google_storage_bucket" "static-site" {
  name          = "devops-terraform-test-501908"
  location      = "europe-west4"
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  cors {
    origin          = ["http://image-store.com"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  soft_delete_policy {
    retention_duration_seconds = 0
  }
}
