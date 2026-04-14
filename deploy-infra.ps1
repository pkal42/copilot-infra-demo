<#
.SYNOPSIS
    Deploys infrastructure via Terraform with init, plan, approval, and apply stages.

.DESCRIPTION
    Production-ready deployment script that executes the full Terraform workflow:
    init → fmt check → validate → plan → approval → apply → capture outputs.
    Includes structured logging, error handling, and deployment artifact generation.

.PARAMETER Environment
    Target environment (e.g., dev, staging, prod). Maps to environments/<env>.tfvars if present,
    otherwise falls back to terraform.tfvars.

.PARAMETER BackendResourceGroup
    Resource group containing the Terraform state storage account.

.PARAMETER BackendStorageAccount
    Storage account name for the Terraform state backend.

.PARAMETER BackendContainer
    Blob container name for the Terraform state file.

.PARAMETER BackendKey
    State file key (blob name) within the container. Defaults to '<Environment>/infra-demo.tfstate'.

.PARAMETER AutoApprove
    Skip the interactive approval prompt. Use in CI/CD pipelines only.

.PARAMETER PlanOnly
    Run through init, fmt, validate, and plan only — do not prompt for or run apply.

.PARAMETER WorkingDirectory
    Path to the Terraform configuration directory. Defaults to the script's own directory.

.EXAMPLE
    .\deploy-infra.ps1 -Environment dev

.EXAMPLE
    .\deploy-infra.ps1 -Environment prod -BackendStorageAccount stprodtfstate -PlanOnly

.EXAMPLE
    .\deploy-infra.ps1 -Environment staging -AutoApprove  # CI/CD usage
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment,

    [Parameter()]
    [string]$BackendResourceGroup = "rg-terraform-state",

    [Parameter()]
    [string]$BackendStorageAccount = "stterraformstate",

    [Parameter()]
    [string]$BackendContainer = "tfstate",

    [Parameter()]
    [string]$BackendKey = "",

    [Parameter()]
    [switch]$AutoApprove,

    [Parameter()]
    [switch]$PlanOnly,

    [Parameter()]
    [string]$WorkingDirectory = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
$Script:LogFile = Join-Path $WorkingDirectory "deploy-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")][string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $Script:LogFile -Value $entry
    switch ($Level) {
        "ERROR"   { Write-Host $entry -ForegroundColor Red }
        "WARN"    { Write-Host $entry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $entry -ForegroundColor Green }
        default   { Write-Host $entry }
    }
}

function Invoke-Step {
    <#
    .SYNOPSIS
        Runs a named deployment step, logs it, and aborts on failure.
    #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    Write-Log "===== Starting step: $Name ====="
    try {
        & $Action
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "Step '$Name' exited with code $LASTEXITCODE"
        }
        Write-Log "Step '$Name' completed successfully." -Level SUCCESS
    }
    catch {
        Write-Log "Step '$Name' failed: $_" -Level ERROR
        Write-Log "See log file for details: $Script:LogFile" -Level ERROR
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
Write-Log "Deployment started for environment: $Environment"
Write-Log "Working directory: $WorkingDirectory"
Write-Log "Log file: $Script:LogFile"

Push-Location $WorkingDirectory
try {
    # Verify Terraform is installed
    Invoke-Step "Check Terraform version" {
        terraform -version | Tee-Object -Variable tfVersion
        Write-Log "Terraform version: $($tfVersion[0])"
    }

    # Verify Azure CLI authentication
    Invoke-Step "Check Azure CLI authentication" {
        $account = az account show --output json 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Not authenticated to Azure. Run 'az login' first."
        }
        $accountObj = $account | ConvertFrom-Json
        Write-Log "Authenticated to subscription: $($accountObj.name) ($($accountObj.id))"
    }

    # ---------------------------------------------------------------------------
    # Resolve backend key and var file
    # ---------------------------------------------------------------------------
    if ([string]::IsNullOrEmpty($BackendKey)) {
        $BackendKey = "$Environment/infra-demo.tfstate"
    }

    $varFile = Join-Path $WorkingDirectory "environments\$Environment.tfvars"
    if (-not (Test-Path $varFile)) {
        $varFile = Join-Path $WorkingDirectory "terraform.tfvars"
        Write-Log "Environment-specific var file not found. Falling back to: $varFile" -Level WARN
    }
    else {
        Write-Log "Using var file: $varFile"
    }

    if (-not (Test-Path $varFile)) {
        Write-Log "No var file found at $varFile. Aborting." -Level ERROR
        exit 1
    }

    # ---------------------------------------------------------------------------
    # Step 1 — Terraform Init
    # ---------------------------------------------------------------------------
    Invoke-Step "terraform init" {
        terraform init `
            -backend-config="resource_group_name=$BackendResourceGroup" `
            -backend-config="storage_account_name=$BackendStorageAccount" `
            -backend-config="container_name=$BackendContainer" `
            -backend-config="key=$BackendKey" `
            -input=false `
            -no-color 2>&1 | ForEach-Object { Write-Log $_ }
    }

    # ---------------------------------------------------------------------------
    # Step 2 — Terraform Format Check
    # ---------------------------------------------------------------------------
    Invoke-Step "terraform fmt -check" {
        $fmtResult = terraform fmt -check -recursive -no-color 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Unformatted files detected:" -Level WARN
            $fmtResult | ForEach-Object { Write-Log "  $_" -Level WARN }
            throw "Run 'terraform fmt -recursive' to fix formatting."
        }
    }

    # ---------------------------------------------------------------------------
    # Step 3 — Terraform Validate
    # ---------------------------------------------------------------------------
    Invoke-Step "terraform validate" {
        terraform validate -no-color 2>&1 | ForEach-Object { Write-Log $_ }
    }

    # ---------------------------------------------------------------------------
    # Step 4 — Terraform Plan
    # ---------------------------------------------------------------------------
    $planFile = Join-Path $WorkingDirectory "tfplan"
    $planOutputFile = Join-Path $WorkingDirectory "plan-$Environment.txt"

    Invoke-Step "terraform plan" {
        terraform plan `
            -var-file="$varFile" `
            -out="$planFile" `
            -input=false `
            -no-color 2>&1 | Tee-Object -FilePath $planOutputFile | ForEach-Object { Write-Log $_ }
    }

    Write-Log "Plan saved to: $planFile"
    Write-Log "Plan text output saved to: $planOutputFile"

    # Summarise the plan
    $planSummary = Get-Content $planOutputFile | Select-String "Plan:"
    if ($planSummary) {
        Write-Log "Plan summary: $planSummary" -Level INFO
    }

    if ($PlanOnly) {
        Write-Log "PlanOnly mode — skipping apply." -Level INFO
        Write-Log "Review the plan at: $planOutputFile"
        exit 0
    }

    # ---------------------------------------------------------------------------
    # Step 5 — Approval Gate
    # ---------------------------------------------------------------------------
    if (-not $AutoApprove) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host " Review the plan above carefully.       " -ForegroundColor Cyan
        Write-Host " Environment: $Environment              " -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        $confirmation = Read-Host "Type 'yes' to apply, or anything else to abort"
        if ($confirmation -ne "yes") {
            Write-Log "Apply aborted by user." -Level WARN
            exit 0
        }
        Write-Log "User confirmed apply."
    }
    else {
        Write-Log "AutoApprove enabled — skipping confirmation." -Level WARN
    }

    # ---------------------------------------------------------------------------
    # Step 6 — Terraform Apply
    # ---------------------------------------------------------------------------
    Invoke-Step "terraform apply" {
        terraform apply -no-color -input=false "$planFile" 2>&1 | ForEach-Object { Write-Log $_ }
    }

    # ---------------------------------------------------------------------------
    # Step 7 — Capture Outputs
    # ---------------------------------------------------------------------------
    $outputFile = Join-Path $WorkingDirectory "deployment-output.json"

    Invoke-Step "Capture Terraform outputs" {
        $outputs = terraform output -json -no-color 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to retrieve Terraform outputs."
        }

        $deploymentRecord = @{
            metadata = @{
                environment   = $Environment
                timestamp     = (Get-Date -Format "o")
                plan_file     = $planFile
                var_file      = $varFile
                backend_key   = $BackendKey
            }
            outputs = ($outputs | ConvertFrom-Json)
        } | ConvertTo-Json -Depth 10

        $deploymentRecord | Set-Content -Path $outputFile -Encoding UTF8
        Write-Log "Deployment outputs written to: $outputFile"
    }

    # ---------------------------------------------------------------------------
    # Done
    # ---------------------------------------------------------------------------
    Write-Log "========================================" -Level SUCCESS
    Write-Log " Deployment to '$Environment' completed successfully." -Level SUCCESS
    Write-Log "========================================" -Level SUCCESS
    Write-Log "Artifacts:"
    Write-Log "  Plan file:        $planFile"
    Write-Log "  Plan text:        $planOutputFile"
    Write-Log "  Outputs JSON:     $outputFile"
    Write-Log "  Log file:         $Script:LogFile"
}
finally {
    Pop-Location
}
