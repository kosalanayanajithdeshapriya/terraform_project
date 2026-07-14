variable "region" {
  description = "The region in which to create the resource"
  default     = "europe-west4"

}

variable "repository_url" {
  description = "The URL of the artifact registry repository"
  type        = string
}

