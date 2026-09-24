variable "environment_name" {
  type        = string
  description = "Container Apps Environment name."
}

variable "app_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "ghcr_username" {
  type        = string
  description = "GitHub username/org that owns the ghcr.io images (used as registry pull credential)."
}

variable "ghcr_token" {
  type        = string
  sensitive   = true
  description = "GitHub PAT with read:packages, used as the ghcr.io registry pull credential."
}

variable "frontend_image" {
  type        = string
  description = "Full ghcr.io image reference, e.g. ghcr.io/<owner>/<app>-frontend:latest."
}

variable "backend_image" {
  type        = string
  description = "Full ghcr.io image reference, e.g. ghcr.io/<owner>/<app>-backend:latest."
}

variable "postgres_admin_username" {
  type    = string
  default = "pgadmin"
}

variable "postgres_database_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
