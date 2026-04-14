# Runbook: Terraform Infrastructure Change

## Purpose

Apply infrastructure changes to the **infra-demo** Azure landing zone managed by Terraform. This stack provisions a resource group, Key Vault, Storage Account, Log Analytics Workspace, VNet, subnets, and NSGs in the **UK South** region.

**State backend:** `azurerm` — stored in `stterraformstate` / `tfstate` / `infra-demo.tfstate` (resource group: `rg-terraform-state`).

---

## Preconditions / Access Checks

| # | Check | How to verify |
|---|-------|---------------|
| 1 | **Azure CLI authenticated** | `az account show` — confirm correct tenant and subscription |
| 2 | **Correct subscription selected** | `az account set --subscription <subscription_id>` |
| 3 | **RBAC permissions** | Operator needs at minimum **Contributor** on the target subscription and **Storage Blob Data Contributor** on the state storage account |
| 4 | **Terraform installed** | `terraform -version` — requires `>= 1.5.0` |
| 5 | **AzureRM provider** | Version `~> 3.90` (pulled automatically on `init`) |
| 6 | **State backend accessible** | `az storage blob list --account-name stterraformstate --container-name tfstate` |
| 7 | **Variables file reviewed** | Verify `terraform.tfvars` has the correct `subscription_id`, `environment`, and `tags` |
| 8 | **Required tags present** | `tags` must include non-empty `environment`, `owner`, and `cost_center` |
| 9 | **No concurrent runs** | Confirm no other operator is currently applying (state lock) |

---

## Commands to Run

### 1. Format check

```bash
terraform fmt -check -recursive
```

Fails if any `.tf` files are not canonically formatted. Fix with `terraform fmt -recursive`.

### 2. Initialize

```bash
terraform init
```

Downloads providers and configures the remote backend. Re-run after any provider or backend changes.

### 3. Validate

```bash
terraform validate
```

Checks syntax and internal consistency (variable references, resource attributes, etc.).

### 4. Plan

```bash
terraform plan -out=tfplan
```

> **Always use `-out`** to save the plan artifact. This guarantees the exact reviewed change set is what gets applied.

Review the plan output carefully:
- Count of resources to **add / change / destroy**
- Any unexpected destroys or replacements (look for `-/+` or `~`)
- Sensitive values or outputs

### 5. Apply

```bash
terraform apply tfplan
```

Applies the saved plan. Do **not** use `terraform apply` without a plan file in production workflows.

### 6. Clean up plan file

```bash
rm tfplan
```

---

## Verification Steps

After a successful apply, verify the deployment:

```bash
# 1. Confirm Terraform outputs
terraform output

# 2. Verify resource group exists
az group show --name rg-infra-demo --output table

# 3. Verify Key Vault
az keyvault show --name kv-infra-demo-dev --output table

# 4. Verify Storage Account
az storage account show --name stinfrademodev --output table

# 5. Verify VNet and subnets
az network vnet show --resource-group rg-infra-demo --name vnet-infra-demo --output table
az network vnet subnet list --resource-group rg-infra-demo --vnet-name vnet-infra-demo --output table

# 6. Verify NSGs
az network nsg list --resource-group rg-infra-demo --output table

# 7. Verify Log Analytics Workspace
az monitor log-analytics workspace show --resource-group rg-infra-demo --workspace-name law-infra-demo-dev --output table

# 8. Confirm state is consistent
terraform plan
# Expected output: "No changes. Your infrastructure matches the configuration."
```

---

## Rollback Steps

### Option A: Revert via Terraform (preferred)

1. **Revert the code change** in Git:
   ```bash
   git revert <commit-sha>
   ```
2. **Plan and apply** the reverted configuration:
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

### Option B: Full destroy (greenfield only)

> ⚠️ Only use this for initial deployments with no live workloads.

```bash
terraform plan -destroy -out=tfplan-destroy
terraform apply tfplan-destroy
```

### Option C: Targeted rollback

Roll back a specific resource without affecting others:

```bash
terraform plan -destroy -target=azurerm_storage_account.main -out=tfplan-targeted
terraform apply tfplan-targeted
```

### Key Vault caveat

The Key Vault has `purge_protection_enabled = true` and `soft_delete_retention_days = 90`. After destruction it enters a soft-deleted state and the **name is reserved for 90 days**. To fully purge (if you have Purge permission):

```bash
az keyvault purge --name kv-infra-demo-dev --location uksouth
```

---

## Common Failure Modes + Mitigations

| Failure | Cause | Mitigation |
|---------|-------|------------|
| **State lock timeout** | Another `apply` or `plan` is running, or a previous run crashed without releasing the lock | Wait for the other run to finish, or force-unlock: `terraform force-unlock <LOCK_ID>` (use with extreme caution) |
| **403 / AuthorizationFailed** | Insufficient RBAC on the subscription or state storage account | Verify role assignments: Contributor on subscription, Storage Blob Data Contributor on state account |
| **Key Vault name conflict** | A soft-deleted vault with the same name already exists | Purge the old vault: `az keyvault purge --name kv-infra-demo-dev` or choose a different name |
| **Storage account name taken** | Storage account names are globally unique; name is already in use | Change the name in `main.tf` (e.g., append a random suffix) |
| **Provider version mismatch** | Local provider cache differs from lock file | Run `terraform init -upgrade` to refresh providers |
| **Backend init failure** | State storage account unreachable or container missing | Verify the storage account exists and the `tfstate` container is created; check network/firewall rules |
| **Validation error on tags** | Missing required tag keys (`environment`, `owner`, `cost_center`) or empty values | Update `terraform.tfvars` to include all required tags with non-empty values |
| **Quota exceeded** | Subscription vCPU, VNet, or resource limits reached | Check quotas: `az vm list-usage --location uksouth -o table`; request an increase via the Azure portal |
| **Drift detected** | Manual changes made outside Terraform | Run `terraform plan` to detect drift, then either import changes or re-apply to reconcile |
