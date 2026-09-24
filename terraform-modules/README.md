# Terraform modules

Reusable modules composed by every generated `<app>-infra` repo (see
[templates/create-application/skeleton/infra/main.tf](../templates/create-application/skeleton/infra/main.tf)).

| Module | Creates |
|---|---|
| [acr](acr/) | Azure Container Registry (admin access disabled — pulls via managed identity) |
| [keyvault](keyvault/) | Key Vault with RBAC authorization |
| [postgresql](postgresql/) | PostgreSQL Flexible Server + database + a randomly generated admin password (output only as a `sensitive` connection string, never as a plain value) |
| [container-apps](container-apps/) | Container Apps Environment, one shared user-assigned managed identity (AcrPull + Key Vault Secrets User), and the frontend + backend Container Apps |
| [networking](networking/) | Not implemented in the POC — placeholder for roadmap phase 1 private networking |

## Versioning (production pattern)

For the POC these are consumed via a `git::` source pinned to `?ref=main` against this same repo.
In production, split them into their own `idp-terraform-modules` repo, tag releases (`v1.0.0`),
and pin every `<app>-infra` repo to a specific tag — so a module change never silently changes
behavior for already-provisioned apps until their infra repo bumps the `ref`.

## Testing a module in isolation

```bash
cd terraform-modules/postgresql
terraform init
terraform plan -var server_name=test-psql -var database_name=testdb \
  -var resource_group_name=rg-test -var location=eastus -var admin_username=pgadmin
```
