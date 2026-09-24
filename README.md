# Internal Developer Platform POC — Backstage on Azure

Self-service "Create Application" workflow: a developer fills in a Backstage form and gets a
fully wired frontend + backend + PostgreSQL database + CI/CD + DEV deployment + Catalog entries,
with zero manual ticket-filing.

This repo contains the actual artifacts for the POC:

```
.
├── docs/
│   ├── architecture.md         # end-to-end + Backstage + Azure architecture (diagrams)
│   └── implementation-guide.md # step-by-step setup, MVP plan, roadmap
├── backstage/                  # app-config snippets, plugin list, org/catalog data
├── templates/create-application/  # the Scaffolder template + skeleton (generated repo content)
├── terraform-modules/          # reusable Terraform modules (postgresql, container-apps, acr, keyvault)
└── github-actions-reusable/    # reusable GitHub Actions workflows called by generated repos
```

Read [docs/architecture.md](docs/architecture.md) first, then
[docs/implementation-guide.md](docs/implementation-guide.md) for the day-by-day build plan
(MVP in 2-3 days) and the production roadmap.

## TL;DR flow

1. Developer opens Backstage → **Create** → **New Application**.
2. Fills in `Application Name`, `Team Name`, `Owner`, `Environment`.
3. Scaffolder ([templates/create-application/template.yaml](templates/create-application/template.yaml)):
   - Creates 3 GitHub repos (`<app>-frontend`, `<app>-backend`, `<app>-infra`) from the skeletons.
   - Pushes a `catalog-info.yaml` into each repo and registers them in the Catalog.
4. Each repo's GitHub Actions workflow runs on push to `main`:
   - `<app>-infra`: `terraform apply` → creates Resource Group, ACR, Postgres Flexible Server,
     Container Apps Environment, Key Vault + secrets.
   - `<app>-frontend` / `<app>-backend`: build container image → push to ACR → `az containerapp update`.
5. Backstage Catalog shows the Application `System` with 4 linked entities (frontend `Component`,
   backend `Component`, database `Resource`, infra `Resource`) carrying live links (repo, deploy
   URL, API URL, DB host) and TechDocs.

See [docs/architecture.md](docs/architecture.md) for diagrams and
[templates/create-application/template.yaml](templates/create-application/template.yaml) for the
actual scaffolder implementation.
