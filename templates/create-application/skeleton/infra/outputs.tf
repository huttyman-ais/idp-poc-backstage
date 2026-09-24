output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "postgres_fqdn" {
  value = module.postgresql.fqdn
}

output "database_name" {
  value = local.database_name
}

output "key_vault_uri" {
  value = module.keyvault.vault_uri
}

output "frontend_url" {
  value = "https://${module.container_apps.frontend_fqdn}"
}

output "backend_url" {
  value = "https://${module.container_apps.backend_fqdn}"
}
