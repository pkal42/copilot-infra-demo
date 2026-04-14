# Infrastructure Demo — Azure Landing Zone

Terraform configuration for a basic Azure landing zone with networking, Key Vault, storage, and monitoring.

## Architecture

- **Resource Group**: Central resource group for all resources
- **Virtual Network**: Hub VNet with app, database, and management subnets
- **Key Vault**: Secrets management with purge protection
- **Storage Account**: GRS-replicated storage with TLS 1.2 minimum
- **Log Analytics**: Centralized logging workspace

## Usage

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## CI/CD

This repository includes a GitHub Actions workflow at `.github/workflows/terraform-ci.yml` that runs on pull requests and performs:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false`
3. `terraform validate`
4. `terraform plan -no-color` (saved as workflow artifacts)
5. Posts the plan output as a pull request comment

### Reading the plan artifact

After the workflow completes, open the workflow run and download the `terraform-plan` artifact. It includes:

- `tfplan` (binary plan file)
- `plan-output.txt` (human-readable plan output)

Use `plan-output.txt` directly for review, or run `terraform show tfplan` locally to inspect the binary plan.

### If `fmt` or `validate` fails

- For `fmt` failures, run `terraform fmt -recursive` locally, then commit the formatting changes.
- For `validate` failures, run `terraform init -backend=false` then `terraform validate` locally, fix the reported configuration issues, and push the fixes.

## Inputs

| Variable | Description | Default |
|---|---|---|
| `subscription_id` | Azure subscription ID | — |
| `environment` | Deployment environment | `dev` |
| `location` | Azure region | `uksouth` |
| `vnet_address_space` | VNet CIDR | `["10.0.0.0/16"]` |
| `subnet_prefixes` | Subnet CIDRs by name | app, db, mgmt |

## Outputs

| Output | Description |
|---|---|
| `resource_group_name` | Resource group name |
| `key_vault_id` | Key Vault resource ID |
| `vnet_id` | Virtual network ID |
| `subnet_ids` | Map of subnet names to IDs |
| `tags` | Resolved tags applied to all resources |

## Tagging & Validation

All resources are tagged consistently via the `tags` variable. Three mandatory tags are enforced at plan time:

| Tag | Purpose |
|---|---|
| `environment` | Deployment environment (e.g. dev, staging, prod) |
| `owner` | Team or individual responsible for the resources |
| `cost_center` | Finance code for cost attribution |

`terraform validate` will fail if any of these keys are missing or empty. A `managed_by = "terraform"` tag is automatically merged in.

### Usage

Set the tags in your `terraform.tfvars`:

```hcl
tags = {
  environment = "dev"
  owner       = "platform-team"
  cost_center = "CC-1234"
  project     = "my-app"   # additional tags are allowed
}
```

The resolved tag map (including the automatic `managed_by` tag) is available via the `tags` output for downstream consumption.
