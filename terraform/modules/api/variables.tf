variable "region" {
  description = "The region in which to create the resource"
  default     = "europe-west4"

}

variable "repository_url" {
  description = "The URL of the artifact registry repository"
  type        = string
}

variable "access_token" {
  description = "OAuth2 access token used to authenticate docker pushes to the Artifact Registry repository"
  type        = string
  sensitive   = true
}

