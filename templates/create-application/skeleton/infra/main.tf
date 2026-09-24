locals {
  # Naming convention shared with the frontend/backend CI/CD workflows — keep in sync.
  resource_group_name = "rg-${var.app_name}-${var.environment}"
  container_app_env    = "cae-${var.app_name}-${var.environment}"
  database_name         = replace(var.app_name, "-", "") == "" ? "appdb" : "${replace(var.app_name, "-", "")}db"

  common_tags = {
    application = var.app_name
    environment = var.environment
    owner       = var.owner
    team        = var.team_name
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# --- Lightweight demo architecture ------------------------------------------
# Registry: GitHub Container Registry (ghcr.io) instead of ACR — sidesteps subscriptions whose
# policy disallows public-network-access container registries.
# Database: PostgreSQL running as a Container App (Azure Files-backed volume) instead of
# PostgreSQL Flexible Server — sidesteps subscriptions where that service is unavailable/blocked.
# Secrets: Container Apps' own built-in secrets instead of Key Vault — avoids needing the
# `User Access Administrator` role (Contributor alone can't create role assignments).
#
# For a "real" subscription without those restrictions, swap this module call for the
# acr + keyvault + postgresql + container-apps composition documented in
# terraform-modules/README.md (production path) — those modules still live in this repo.
module "container_apps" {
  source              = "git::https://github.com/${{values.githubOrg}}/idp-poc-backstage.git//terraform-modules/container-apps?ref=main"
  environment_name     = local.container_app_env
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  app_name             = var.app_name
  tags                 = local.common_tags

  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token

  # Public placeholder so the Container Apps + revisions exist before CI has ever pushed a real
  # image (our CI only ever pushes SHA-tagged images, never :latest, so referencing the real ghcr
  # image here would create a bootstrap deadlock). The frontend/backend CI/CD workflows overwrite
  # this via `az containerapp update` on their very next run.
  frontend_image = "mcr.microsoft.com/k8se/quickstart:latest"
  backend_image  = "mcr.microsoft.com/k8se/quickstart:latest"

  postgres_admin_username = var.postgres_admin_username
  postgres_database_name  = local.database_name
}
