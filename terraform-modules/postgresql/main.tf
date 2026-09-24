resource "random_password" "admin" {
  length      = 24
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
  # avoid characters Postgres/ARM sometimes choke on in connection strings
  override_special = "-_!#%"
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  version    = "16"
  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  administrator_login    = var.admin_username
  administrator_password = random_password.admin.result

  zone                         = "1"
  geo_redundant_backup_enabled = false
  backup_retention_days        = 7

  # POC: public network access + firewall allow-list. Roadmap phase 1 moves this to
  # VNet-integrated private access only (delegated subnet + private DNS zone).
  public_network_access_enabled = true

  tags = var.tags

  lifecycle {
    ignore_changes = [zone] # Azure may rebalance zone on restarts; not a drift we care about
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
