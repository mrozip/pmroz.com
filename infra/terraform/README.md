# Terraform Azure Infrastructure

This directory contains two Terraform roots:

- `bootstrap` provisions the Azure Storage backend used for remote Terraform state.
- `.` provisions the Azure footprint for `pmroz.com`.

The app root creates only:

- Azure resource group
- Azure Static Web App on the Free SKU

It intentionally does not create an App Service Plan, database, CDN, or other paid runtime dependency.

## GitHub Actions

Terraform workflow logic is shared through `.github/actions/terraform-root`.

| Workflow | Purpose |
| --- | --- |
| `.github/workflows/terraform.yml` | Manual plan, apply, destroy, and optional backend bootstrap |
| `.github/workflows/terraform-validate.yml` | PR validation and same-repository PR planning |

Terraform uses GitHub Actions OpenID Connect with Azure. No Azure client secret is required.

The PR workflow always runs backendless validation. It also runs a remote-state plan for same-repository PR branches, but skips forked pull requests so untrusted Terraform code cannot receive Azure OIDC credentials.

## Backend Bootstrap

The remote state backend is managed by `infra/terraform/bootstrap`. The manual `Terraform` workflow can apply this root before the app root when `bootstrap_state` is enabled.

The bootstrap root creates:

- State resource group
- Storage account
- Private state container
- `Storage Blob Data Contributor` assignment for the current GitHub Actions Azure principal

On the first bootstrap run, the workflow falls back to local bootstrap state, applies the backend resources, then migrates that bootstrap state into the new Azure backend under:

```text
hugo-pmroz/bootstrap.tfstate
```

Override that key with the `TF_BOOTSTRAP_STATE_KEY` GitHub variable if needed.

The state resource group and storage account use `prevent_destroy = true` because they are backend dependencies, not website runtime resources.

## Sandbox Apply

To test a new Azure resource group and Static Web App from GitHub without touching production state, run the `Terraform` workflow manually with:

| Input | Example |
| --- | --- |
| `operation` | `apply` |
| `bootstrap_state` | `true` when the backend must be created or updated |
| `resource_group_name` | `rg-hugo-pmroz-app-sbx` |
| `static_web_app_name` | `swa-hugo-pmroz-app-sbx` |
| `state_key` | `hugo-pmroz/sbx/app.tfstate` |
| `location` | `eastus2` |
| `sku` | `Free` |

Use the same `state_key`, `resource_group_name`, and `static_web_app_name` with `operation=destroy` to remove the sandbox app resources. The bootstrap state backend is protected from destroy.

## Required GitHub Variables

Set these as repository or `terraform` environment variables in GitHub:

| Variable | Description |
| --- | --- |
| `AZURE_CLIENT_ID` | Client ID of the Azure app registration or managed identity used by GitHub Actions. |
| `AZURE_TENANT_ID` | Azure tenant ID. |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID. |
| `TF_STATE_STORAGE_ACCOUNT_NAME` | Globally unique storage account name for Terraform state. |

Optional variables:

| Variable | Default |
| --- | --- |
| `TF_STATE_RESOURCE_GROUP_NAME` | `rg-hugo-pmroz-state-shared` |
| `TF_STATE_CONTAINER_NAME` | `tfstate` |
| `TF_STATE_LOCATION` | `eastus2` |
| `TF_BOOTSTRAP_STATE_KEY` | `hugo-pmroz/bootstrap.tfstate` |
| `TF_STATE_KEY` | `hugo-pmroz/prod/app.tfstate` |
| `TF_RESOURCE_GROUP_NAME` | `rg-hugo-pmroz-app-prod` |
| `TF_STATIC_WEB_APP_NAME` | `swa-hugo-pmroz-app-prod` |
| `TF_LOCATION` | `eastus2` |
| `TF_SKU` | `Free` |
| `TF_BOOTSTRAP_ASSIGN_CURRENT_PRINCIPAL_BLOB_DATA_CONTRIBUTOR` | `true` |

Manual workflow inputs override app resource names, location, SKU, and app state key for that run.

## Azure Setup

Create an Azure app registration or managed identity for GitHub Actions and configure a federated credential for the GitHub environment named `terraform`.

The identity needs:

- Contributor permission for the subscription or target resource groups managed by Terraform.
- Storage Blob Data Contributor permission for the Terraform state storage account after bootstrap.
- Owner or User Access Administrator permission only when the bootstrap root must assign the storage data-plane role.

Run the `Terraform` workflow with `bootstrap_state` enabled to create or update the Azure Storage backend through Terraform. After the first successful bootstrap, future bootstrap runs use the remote bootstrap state automatically.

If the old shell-based bootstrap already created the backend resources, the workflow attempts to import the existing resource group, storage account, and container before planning. If the storage blob role assignment already exists outside Terraform and causes a duplicate assignment error, set `TF_BOOTSTRAP_ASSIGN_CURRENT_PRINCIPAL_BLOB_DATA_CONTRIBUTOR` to `false` or import that role assignment manually.

Keep the deployment workflow secret pointed at the existing production Static Web App:

```text
AZURE_STATIC_WEB_APPS_API_TOKEN
```

Do not replace it with a sandbox deployment token unless you intentionally want the deployment workflow to target that sandbox app.

## Configuration

The app root default configuration creates:

| Setting | Default |
| --- | --- |
| Resource group | `rg-hugo-pmroz-app-prod` |
| Static Web App | `swa-hugo-pmroz-app-prod` |
| Location | `eastus2` |
| SKU | `Free` |
