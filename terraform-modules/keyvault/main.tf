data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false # POC only — enable for prod (roadmap phase 1)
  soft_delete_retention_days = 7
  rbac_authorization_enabled = true # access via RBAC role assignments, not vault access policies
  tags                       = var.tags
}

# The Terraform identity itself needs to write the initial db-connection-string secret.
resource "azurerm_role_assignment" "tf_runner_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
