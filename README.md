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

Pull requests run the `Terraform CI` GitHub Actions workflow. It executes:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false`
3. `terraform validate`
4. `terraform plan -no-color` and saves the output as a workflow artifact
5. Posts the plan output back to the pull request as a comment

To read the plan artifact:

- Open the pull request checks for **Terraform CI**
- Open the workflow run and download the **terraform-plan-output** artifact
- Review `plan-output.txt` for the full plan output

If `fmt` or `validate` fails:

- Run `terraform fmt -recursive` locally to fix formatting
- Re-run `terraform init -backend=false && terraform validate` to confirm config is valid
- Commit the fixes and push to update the pull request checks

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
