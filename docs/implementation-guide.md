# Implementation Guide

## 0. Prerequisites

- Azure subscription + `az` CLI logged in, `Owner` or `Contributor`+`User Access Administrator`
  on a resource group scope (needed to create role assignments for managed identities).
- A GitHub organization you control, and a **GitHub App** (preferred) or fine-grained PAT with
  `repo`, `workflow`, `admin:org` (read) scopes for Backstage to create repos.
- Node.js 20.x, Yarn (classic or berry — match whatever `npx @backstage/create-app` scaffolds),
  Terraform ≥ 1.7, Docker.
- A DNS-friendly app name convention, e.g. lowercase, hyphenated: `payments-api`, not `Payments API`.

## 1. Bootstrap Backstage

```bash
npx @backstage/create-app@latest --path backstage-app
cd backstage-app
yarn install
```

Install the plugins from [architecture.md §3](architecture.md#3-required-plugins):

```bash
yarn --cwd packages/backend add \
  @backstage/plugin-scaffolder-backend-module-github \
  @backstage/plugin-catalog-backend-module-github \
  @backstage/plugin-auth-backend-module-github-provider

yarn --cwd packages/app add @backstage-community/plugin-github-actions
```

Merge the config from [backstage/app-config.yaml](../backstage/app-config.yaml) into your
generated `app-config.yaml` / `app-config.production.yaml` (GitHub integration, auth provider,
catalog locations, TechDocs storage).

Run locally to verify before touching Azure:

```bash
yarn dev
```

## 2. Wire up GitHub integration

1. Create a GitHub App (Settings → Developer settings → GitHub Apps) scoped to your org, with:
   repository permissions `Administration: RW`, `Contents: RW`, `Pull requests: RW`,
   `Workflows: RW`; install it on the org (all repos, or the target repos once created — for the
   POC, "all repos" is simplest).
2. Store `appId`, `clientId`, `clientSecret`, `privateKey`, `webhookSecret` as Backstage secrets
   (env vars referenced via `${...}` in `app-config.yaml` — see the file for exact keys).
3. Add the GitHub OAuth provider for developer sign-in (same App, or a separate OAuth App).

## 3. Set up Terraform remote state

One-time, manual (not templated — this is platform infra, not per-app infra):

```bash
az group create -n rg-idp-platform -l eastus
az storage account create -n stidptfstate<rand> -g rg-idp-platform -l eastus --sku Standard_LRS
az storage container create -n tfstate --account-name stidptfstate<rand>
```

Each generated `<app>-infra` repo's `backend.tf` points at this storage account with a unique
state key `<app>/<env>.tfstate` (see [templates/.../infra/backend.tf](../templates/create-application/skeleton/infra/backend.tf)).

## 4. Set up GitHub OIDC → Azure federated credentials (no static cloud secrets)

```bash
az ad app create --display-name "gh-oidc-idp-poc"
APP_ID=$(az ad app list --display-name gh-oidc-idp-poc --query "[0].appId" -o tsv)
az ad sp create --id $APP_ID
az role assignment create --assignee $APP_ID --role Contributor \
  --scope /subscriptions/<sub-id>

az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-org-any-repo-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<your-org>/*:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

Store `AZURE_CLIENT_ID` (=`$APP_ID`), `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` as **GitHub org
-level Actions variables** (not repo secrets — they're not sensitive and need to reach every
generated repo without per-repo setup). This is the single biggest simplification that makes the
"one template → three repos → working CI/CD with zero manual secret-copying" flow possible.

## 5. Author the Scaffolder template

Already written: [templates/create-application/template.yaml](../templates/create-application/template.yaml)
+ [skeleton/](../templates/create-application/skeleton/). It's registered as a catalog `location`
in [backstage/app-config.yaml](../backstage/app-config.yaml) (`catalog.locations`), which is
enough for it to appear under **Create** in the Backstage UI.

## 6. Author the Terraform modules

Already written under [terraform-modules/](../terraform-modules/):
`postgresql`, `container-apps`, `acr`, `keyvault`. The generated `<app>-infra/main.tf` composes
them (`source = "git::https://github.com/<org>/idp-terraform-modules.git//postgresql?ref=v1"` in
production; for the POC, a relative path or a pinned tag against this repo works fine).

## 7. Try the golden path end-to-end

1. `Create` → `New Application` in Backstage UI.
2. Fill `myapp` / `platform-team` / `alice` / `dev`.
3. Watch the Scaffolder task log — repos get created, code pushed, catalog registered.
4. Watch GitHub Actions in `myapp-infra` → `terraform apply` completes → outputs show ACR login
   server, Postgres FQDN, Container Apps default domains.
5. Watch GitHub Actions in `myapp-frontend` / `myapp-backend` → image build+push → `az
   containerapp update`.
6. Back in Backstage Catalog → `System: myapp` → see 4 linked entities with live links.

---

## MVP scope — completable in 2–3 days

Cut ruthlessly to prove the self-service loop works; harden later (see roadmap).

**Day 1 — Backstage skeleton + template mechanics**
- `create-app`, install scaffolder/catalog/github plugins, GitHub App auth.
- `template.yaml` with the 4 fields (name, team, owner, environment) and the 3
  `publish:github` actions creating empty repos + `fetch:template` populating skeletons.
- Confirm: clicking Create produces 3 real GitHub repos with the skeleton content and they show
  up (manually registered is fine for Day 1) in the Catalog.

**Day 2 — Terraform + Azure provisioning**
- Write the 4 Terraform modules (postgresql, acr, container-apps, keyvault) — POC versions, no
  private networking yet, single environment.
- `terraform.yaml` GitHub Actions workflow in `-infra` repo: OIDC login, `plan` on PR, `apply` on
  merge to `main`.
- Confirm: merging the Scaffolder's initial commit to `-infra`'s `main` (Scaffolder can commit
  straight to `main` for POC — no PR review gate yet) stands up real Azure resources.

**Day 3 — App deploy + Catalog auto-registration + polish**
- `ci-cd.yaml` in `-frontend`/`-backend`: build, push to ACR, `az containerapp update`.
- Scaffolder's `catalog:register` action wired for all 4 entities automatically (remove the
  manual step from Day 1).
- Populate catalog entity annotations with real output links (deploy URL, API URL) via a small
  follow-up step: infra workflow writes outputs to a `outputs.json` the entity page or a custom
  scaffolder step reads back — for the strict 3-day MVP, hardcode the *predictable* Container
  Apps FQDN pattern (`https://<app>-frontend.<aca-env-default-domain>`) into the catalog entity
  at scaffold time instead of round-tripping infra outputs; wire the fully dynamic version in the
  roadmap phase.
- TechDocs: add `mkdocs.yml` + `docs/index.md` to each skeleton, confirm rendering.

**Explicitly out of scope for the 3-day MVP** (all called out in the roadmap):
private VNet-only Postgres, PR-gated infra changes, RBAC/permission framework, multi-environment
promotion (dev→staging→prod), drift detection, cost controls, secret rotation, blue/green
deploys, dynamic catalog-link back-fill from Terraform outputs.

---

## Roadmap — production-grade platform

| Phase | Theme | Key items |
|---|---|---|
| 1. Harden infra | Security | Private VNet-integrated Postgres (no public endpoint), Key Vault firewall + private endpoint, disable local Postgres admin auth in favor of Entra ID auth, `terraform plan` required as a PR check before `apply` (no more direct-to-main from Scaffolder) |
| 2. Multi-environment | Promotion | Add `staging`/`prod` as a second Scaffolder parameter path or a separate "Promote" template; per-env Terraform workspaces/state keys; environment-specific approval gates (GitHub Environments + required reviewers) in Actions |
| 3. Golden paths, not one template | Platform maturity | Split into composable templates (frontend-only, backend-only, "add a database to existing app", "add a queue") instead of one monolithic "create everything"; template versioning |
| 4. Catalog depth | Discoverability | Full GitHub org auto-discovery (`catalog-backend-module-github`) instead of Scaffolder-time registration only; `Domain`/`System`/`API` entities properly modeled with OpenAPI specs served via TechDocs; cost-insights plugin wired to Azure Cost Management export |
| 5. Governance | Guardrails | `permission-backend` with RBAC (who can create apps, who can approve prod promotion); policy-as-code on Terraform (OPA/Conftest or Azure Policy) enforcing tagging, SKU ceilings, network rules |
| 6. Operability | Day-2 | Drift detection (scheduled `terraform plan` + alert), automated secret rotation for Postgres admin creds via Key Vault + rotation function, SLO dashboards surfaced in Backstage (via a metrics plugin backed by Azure Monitor), scale-out from Container Apps to AKS as a per-app opt-in for workloads that outgrow it |
| 7. Developer experience | Adoption | Backstage Scorecards/soundcheck-style checks (has TechDocs? has on-call rotation? has SLO?), self-service "Create" catalog beyond app skeletons (add a Kafka topic, request a new environment), Slack/Teams notifications on scaffold + deploy events |

The architectural bet this POC makes — **Scaffolder only ever commits code, GitHub Actions does
all real provisioning/deployment** — is exactly the shape you want at each of these phases; later
phases add gates, environments, and policy around that same loop rather than replacing it.
