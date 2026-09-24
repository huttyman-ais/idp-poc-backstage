locals {
  # Naming convention shared with the frontend/backend CI/CD workflows — keep in sync.
  resource_group_name = "rg-${var.app_name}-${var.environment}"
  acr_name             = "acr${replace(var.app_name, "-", "")}${var.environment}" # alphanumeric only
  container_app_env    = "cae-${var.app_name}-${var.environment}"
  key_vault_name        = substr("kv-${var.app_name}-${var.environment}", 0, 24) # KV names cap at 24 chars
  postgres_server_name  = "psql-${var.app_name}-${var.environment}"
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

# --- Shared modules ---------------------------------------------------------
# In production these `source` values point at a dedicated, versioned
# `idp-terraform-modules` repo, e.g.:
#   source = "git::https://github.com/<org>/idp-terraform-modules.git//postgresql?ref=v1.0.0"
# For this POC they're pinned against this same repo's terraform-modules/ directory.

module "acr" {
  source              = "git::https://github.com/<org>/idp-poc-backstage.git//terraform-modules/acr?ref=main"
  name                = local.acr_name
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  tags                 = local.common_tags
}

module "keyvault" {
  source              = "git::https://github.com/<org>/idp-poc-backstage.git//terraform-modules/keyvault?ref=main"
  name                = local.key_vault_name
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  tags                 = local.common_tags
}

module "postgresql" {
  source              = "git::https://github.com/<org>/idp-poc-backstage.git//terraform-modules/postgresql?ref=main"
  server_name          = local.postgres_server_name
  database_name        = local.database_name
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  admin_username        = var.postgres_admin_username
  tags                 = local.common_tags
}

# Store the connection string Terraform just generated straight into Key Vault —
# it is never printed to a GitHub Actions log or stored anywhere else.
resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "db-connection-string"
  value        = module.postgresql.connection_string
  key_vault_id = module.keyvault.id
}

module "container_apps" {
  source              = "git::https://github.com/<org>/idp-poc-backstage.git//terraform-modules/container-apps?ref=main"
  environment_name     = local.container_app_env
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  app_name             = var.app_name
  acr_login_server      = module.acr.login_server
  acr_id                = module.acr.id
  key_vault_id          = module.keyvault.id
  key_vault_uri         = module.keyvault.vault_uri
  tags                 = local.common_tags

  # Placeholder images so the Container Apps + revisions exist before CI ever runs;
  # the frontend/backend CI/CD workflows immediately overwrite these via `az containerapp update`.
  frontend_image = "mcr.microsoft.com/k8se/quickstart:latest"
  backend_image  = "mcr.microsoft.com/k8se/quickstart:latest"
}
