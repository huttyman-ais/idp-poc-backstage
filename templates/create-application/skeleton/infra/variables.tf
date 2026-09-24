variable "app_name" {
  type        = string
  default     = "${{values.appName}}"
  description = "Application name, used as prefix for all resource names."
}

variable "environment" {
  type        = string
  default     = "${{values.environment}}"
  description = "Target environment (dev/staging/prod)."
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region for all resources."
}

variable "owner" {
  type        = string
  default     = "${{values.owner}}"
}

variable "team_name" {
  type        = string
  default     = "${{values.teamName}}"
}

variable "postgres_admin_username" {
  type        = string
  default     = "pgadmin"
  description = "Postgres admin login. Password is generated randomly and stored only as a Container App secret."
}

variable "ghcr_username" {
  type        = string
  default     = "${{values.githubOrg}}"
  description = "GitHub owner whose Container Registry (ghcr.io) hosts the frontend/backend images."
}

variable "ghcr_token" {
  type        = string
  sensitive   = true
  description = "GitHub PAT with read:packages, used as the ghcr.io pull credential. Set via TF_VAR_ghcr_token in CI (see terraform.yaml) — never given a default."
}
