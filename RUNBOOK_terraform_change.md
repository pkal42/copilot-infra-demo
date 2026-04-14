# Runbook: Terraform Change Deployment

## Purpose

Standard operating procedure for planning, applying, and verifying Terraform infrastructure changes. This runbook is environment-agnostic and should be followed for every change regardless of target subscription or workspace.

---

## Preconditions / Access Checks

| # | Check | Command / Action |
|---|-------|-----------------|
| 1 | **Terraform installed** | `terraform -version` — confirm version matches the project's `required_version` constraint |
| 2 | **Authenticated to Azure** | `az account show` — confirm correct subscription and tenant |
| 3 | **Correct subscription selected** | `az account set --subscription <SUBSCRIPTION_ID>` |
| 4 | **Remote state accessible** | `terraform init` succeeds without state-lock errors |
| 5 | **Required permissions** | Confirm your identity has Contributor (or scoped role) on the target resource group / subscription |
| 6 | **Branch is up to date** | `git pull origin main` — avoid drift from other engineers' changes |
| 7 | **No active state lock** | If `terraform plan` reports a lock, confirm no other apply is in progress before force-unlocking |

---

## Commands to Run

### 1. Format

```bash
terraform fmt -check -recursive
```

- Fails if any `.tf` files are not canonically formatted.
- Fix with `terraform fmt -recursive` and commit before proceeding.

### 2. Validate

```bash
terraform validate
```

- Catches syntax errors, missing required arguments, and provider schema violations.
- Must pass cleanly before planning.

### 3. Plan

```bash
terraform plan -out=tfplan
```

- **Always** use `-out` so the exact reviewed plan is what gets applied.
- Review the output for:
  - Unexpected **destroy** or **replace** actions.
  - Resources marked `forces replacement` — these cause downtime.
  - Sensitive values or secrets that should not appear in logs.
- For a specific environment, supply the matching var file:

```bash
terraform plan -var-file=environments/<ENV>.tfvars -out=tfplan
```

### 4. Apply

```bash
terraform apply tfplan
```

- Uses the saved plan file — no interactive approval prompt.
- Monitor output for errors; Terraform will stop on first failure but already-created resources will persist.

---

## Verification Steps

| # | Check | Command / Action |
|---|-------|-----------------|
| 1 | **Apply completed without errors** | Confirm `Apply complete! Resources: N added, N changed, N destroyed.` in output |
| 2 | **Outputs are correct** | `terraform output` — verify key outputs (resource IDs, names, endpoints) |
| 3 | **State is consistent** | `terraform plan` — should report `No changes. Infrastructure is up-to-date.` |
| 4 | **Resources exist in Azure** | `az resource list --resource-group <RG_NAME> --output table` |
| 5 | **Connectivity / functionality** | Run any applicable smoke tests (e.g., curl an endpoint, verify DNS, check NSG rules allow expected traffic) |
| 6 | **Monitoring active** | Confirm resources appear in Log Analytics / Azure Monitor and alerts are firing as expected |

---

## Rollback Steps

### Option A — Revert to Previous Plan (preferred)

If the Terraform code has not been merged or was just merged:

```bash
git revert <COMMIT_SHA>
terraform plan -out=tfplan-rollback
# Review the rollback plan carefully
terraform apply tfplan-rollback
```

### Option B — Targeted Destroy

Remove only the newly created resources:

```bash
terraform destroy -target=<RESOURCE_ADDRESS>
# Repeat for each resource, respecting dependency order (dependents first)
```

### Option C — Full Destroy (non-production only)

```bash
terraform destroy
```

> ⚠️ **Never run `terraform destroy` without `-target` in production** unless a full teardown is explicitly approved.

### Rollback Caveats

- **Key Vaults with purge protection**: Soft-deleted vaults reserve the name for the retention period (default 90 days). You cannot recreate a vault with the same name until the retention expires or you recover it with `az keyvault recover --name <NAME>`.
- **Stateful resources** (databases, storage accounts): Destroying removes data permanently unless backups exist. Confirm backup/recovery strategy before destroying.
- **DNS / networking**: Destroying public IPs or DNS zones causes immediate connectivity loss for anything referencing them.

---

## Common Failure Modes + Mitigations

| Failure | Symptoms | Mitigation |
|---------|----------|------------|
| **State lock contention** | `Error: Error locking state` | Confirm no other apply is running. If orphaned, run `terraform force-unlock <LOCK_ID>`. |
| **Naming conflict** | `ConflictError` or `already exists` on globally-unique resources (Storage Accounts, Key Vaults) | Pre-check availability: `az storage account check-name`, `az keyvault list-deleted`. Use unique naming conventions with environment/region prefixes. |
| **Quota exceeded** | `QuotaExceeded` or `SkuNotAvailable` | Check quota with `az vm list-usage --location <REGION>`. Request increase via Azure portal or switch to an available SKU/region. |
| **Permission denied** | `AuthorizationFailed` | Verify role assignments: `az role assignment list --assignee <PRINCIPAL_ID>`. Request Contributor or the minimum required role. |
| **Provider version mismatch** | `Incompatible provider version` | Run `terraform init -upgrade` to update providers within the version constraints defined in `required_providers`. |
| **Partial apply failure** | Some resources created, others failed | Do **not** re-run `plan` with the old plan file. Run a fresh `terraform plan -out=tfplan` to reconcile state, review, then apply. |
| **Drift detected** | `terraform plan` shows unexpected changes on resources not in your changeset | Investigate manual changes in Azure portal. Either import them with `terraform import` or revert them in the portal, then re-plan. |
| **Timeout on long-running resources** | `context deadline exceeded` | Increase provider timeouts in the resource block (`timeouts { create = "60m" }`). Re-run apply — Terraform will pick up where it left off if the resource is still provisioning. |
