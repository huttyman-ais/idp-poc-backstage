terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # One-time platform setup: see docs/implementation-guide.md §3.
  # Each app/environment gets its own state key so repos never collide.
  backend "azurerm" {
    resource_group_name  = "rg-idp-platform"
    storage_account_name = "${{values.terraformStateStorageAccount}}"
    container_name        = "tfstate"
    key                   = "${{values.appName}}/${{values.environment}}.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
