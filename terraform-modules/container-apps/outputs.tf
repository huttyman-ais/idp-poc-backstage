output "frontend_fqdn" {
  value = azurerm_container_app.frontend.ingress[0].fqdn
}

output "backend_fqdn" {
  value = azurerm_container_app.backend.ingress[0].fqdn
}

output "identity_principal_id" {
  value = azurerm_user_assigned_identity.apps.principal_id
}
