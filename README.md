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

Pull requests run the **Terraform CI** workflow at `.github/workflows/terraform-ci.yml`.
It executes:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false`
3. `terraform validate`
4. `terraform plan -no-color` and stores the output as the `terraform-plan` artifact
5. Posts the plan output to the pull request as a comment

### Reading the plan artifact

1. Open the pull request checks and select the **Terraform CI** run.
2. Download the `terraform-plan` artifact.
3. Open `terraform-plan.txt` to review the exact plan output produced in CI.

### If fmt or validate fails

- For `fmt` failures, run `terraform fmt -recursive` locally and commit the formatting changes.
- For `validate` failures, run `terraform init -backend=false` and `terraform validate` locally, fix the reported configuration issue, and push the fix.

## Inputs

| Variable | Description | Default |
|---|---|---|
| `subscription_id` | Azure subscription ID | — |
| `environment` | Deployment environment | `dev` |
| `location` | Azure region | `uksouth` |
| `vnet_address_space` | VNet CIDR | `["10.0.0.0/16"]` |
| `subnet_prefixes` | Subnet CIDRs by name | app, db, mgmt |
| `tags` | Resource tags (must include `owner` and `cost_center`) | `{}` |

## Tagging & Validation

Every resource is tagged with a merged set of **mandatory** and user-supplied tags.
The mandatory tags are:

| Tag | Source |
|---|---|
| `environment` | Auto-set from `var.environment` |
| `owner` | Must be provided in `var.tags` |
| `cost_center` | Must be provided in `var.tags` |

`terraform validate` (and `terraform plan`) will **fail** if `owner` or `cost_center`
is missing or empty in the `tags` variable. The `environment` tag is always injected
automatically, so you don't need to include it in `tags`.

Example `terraform.tfvars`:

```hcl
tags = {
  owner       = "platform-team"
  cost_center = "CC-12345"
}
```

The resolved tag map is exposed via the `tags` output for downstream modules.

## Outputs

| Output | Description |
|---|---|
| `resource_group_name` | Resource group name |
| `key_vault_id` | Key Vault resource ID |
| `vnet_id` | Virtual network ID |
| `subnet_ids` | Map of subnet names to IDs |
| `tags` | Resolved tags applied to all resources |
