output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "database_name" {
  value = local.database_name
}

output "postgres_internal_host" {
  value = module.container_apps.postgres_internal_host
}

output "frontend_url" {
  value = "https://${module.container_apps.frontend_fqdn}"
}

output "backend_url" {
  value = "https://${module.container_apps.backend_fqdn}"
}
