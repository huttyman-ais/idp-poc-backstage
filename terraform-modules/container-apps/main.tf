resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.environment_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_container_app_environment" "this" {
  name                       = var.environment_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  tags                       = var.tags
  # No custom VNet for the POC — Azure provisions a managed one automatically.
  # Roadmap phase 1: set infrastructure_subnet_id to a delegated subnet for private networking.
}

# --- Lightweight demo Postgres: a container, not a managed PaaS service ---------------------
# Swaps out for terraform-modules/postgresql (Flexible Server) in subscriptions whose policy
# allows it. Runs on the container's own ephemeral disk — data does NOT survive a restart.
# Azure Files (SMB) was tried first but Postgres's initdb needs POSIX chmod/chown semantics
# that SMB-backed shares don't support ("Operation not permitted"); proper persistence would
# need Premium NFS-backed file shares, which is real scope/cost beyond a lightweight demo.

resource "random_password" "postgres_admin" {
  length           = 24
  special          = true
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "-_"
}

resource "azurerm_container_app" "postgres" {
  name                         = "${var.app_name}-postgres"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  secret {
    name  = "postgres-admin-password"
    value = random_password.postgres_admin.result
  }

  template {
    min_replicas = 1 # no scale-to-zero for the stateful DB
    max_replicas = 1
    container {
      name   = "postgres"
      image  = "postgres:16-alpine"
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "POSTGRES_USER"
        value = var.postgres_admin_username
      }
      env {
        name        = "POSTGRES_PASSWORD"
        secret_name = "postgres-admin-password"
      }
      env {
        name  = "POSTGRES_DB"
        value = var.postgres_database_name
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 5432
    transport        = "tcp"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

locals {
  postgres_host = "${azurerm_container_app.postgres.name}.internal.${azurerm_container_app_environment.this.default_domain}"
  database_url  = "postgresql://${var.postgres_admin_username}:${random_password.postgres_admin.result}@${local.postgres_host}:5432/${var.postgres_database_name}?sslmode=disable"
}

# --- Frontend / backend apps, pulling from GitHub Container Registry -------------------------

resource "azurerm_container_app" "backend" {
  name                         = "${var.app_name}-backend"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  secret {
    name  = "ghcr-token"
    value = var.ghcr_token
  }
  secret {
    name  = "database-url"
    value = local.database_url
  }

  registry {
    server               = "ghcr.io"
    username             = var.ghcr_username
    password_secret_name = "ghcr-token"
  }

  template {
    min_replicas = 0 # scale-to-zero is safe here: ghcr pull credential is a durable PAT, not a job-scoped token
    max_replicas = 2
    container {
      name   = "backend"
      image  = var.backend_image
      cpu    = 0.5
      memory = "1Gi"
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name  = "PORT"
        value = "3001"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3001
    transport        = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [azurerm_container_app.postgres]
}

resource "azurerm_container_app" "frontend" {
  name                         = "${var.app_name}-frontend"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  secret {
    name  = "ghcr-token"
    value = var.ghcr_token
  }

  registry {
    server               = "ghcr.io"
    username             = var.ghcr_username
    password_secret_name = "ghcr-token"
  }

  template {
    min_replicas = 0
    max_replicas = 2
    container {
      name   = "frontend"
      image  = var.frontend_image
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
