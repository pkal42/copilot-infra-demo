<#
.SYNOPSIS
    Deploys the infra-demo Terraform configuration with full logging and error handling.

.DESCRIPTION
    Runs the Terraform workflow (init → plan → apply) for the infra-demo stack.
    Captures plan output for review, prompts for confirmation before apply,
    and writes Terraform outputs to a JSON file on success.

.PARAMETER Environment
    Target environment (e.g., dev, staging, prod). Defaults to "dev".

.PARAMETER BackendResourceGroup
    Resource group containing the Terraform state storage account.

.PARAMETER BackendStorageAccount
    Name of the storage account holding Terraform state.

.PARAMETER BackendContainer
    Blob container name for the state file.

.PARAMETER BackendKey
    Blob key (path) for the state file. Defaults to "infra-demo.tfstate".

.PARAMETER VarFile
    Path to the .tfvars file. Defaults to "terraform.tfvars".

.PARAMETER AutoApprove
    Skip the interactive confirmation prompt (for CI/CD pipelines).

.PARAMETER LogDirectory
    Directory for log files. Defaults to ".deploy-logs" in the script root.

.EXAMPLE
    .\deploy-infra.ps1 -Environment dev

.EXAMPLE
    .\deploy-infra.ps1 -Environment prod -AutoApprove -VarFile prod.tfvars
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",

    [Parameter()]
    [string]$BackendResourceGroup = "rg-terraform-state",

    [Parameter()]
    [string]$BackendStorageAccount = "stterraformstate",

    [Parameter()]
    [string]$BackendContainer = "tfstate",

    [Parameter()]
    [string]$BackendKey = "infra-demo.tfstate",

    [Parameter()]
    [string]$VarFile = "terraform.tfvars",

    [Parameter()]
    [switch]$AutoApprove,

    [Parameter()]
    [string]$LogDirectory = (Join-Path $PSScriptRoot ".deploy-logs")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Logging ──────────────────────────────────────────────────────────────────

if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile    = Join-Path $LogDirectory "deploy-${Environment}-${timestamp}.log"

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    $entry = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    $entry | Tee-Object -FilePath $logFile -Append | Write-Host -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN"  { "Yellow" }
            default { "Cyan" }
        }
    )
}

# ── Prerequisite checks ─────────────────────────────────────────────────────

function Assert-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Log "'$Name' is not installed or not on PATH." -Level ERROR
        throw "Missing prerequisite: $Name"
    }
}

function Invoke-Terraform {
    param(
        [string]$StepName,
        [string[]]$Arguments
    )
    Write-Log "Running: terraform $($Arguments -join ' ')"
    $output = & terraform @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    $outputStr = $output | Out-String
    $outputStr | Out-File -FilePath $logFile -Append -Encoding utf8

    if ($exitCode -ne 0) {
        Write-Log "terraform $StepName failed (exit code $exitCode)" -Level ERROR
        Write-Log $outputStr -Level ERROR
        throw "Terraform $StepName failed with exit code $exitCode."
    }

    return $outputStr
}

# ── Main ─────────────────────────────────────────────────────────────────────

try {
    Write-Log "═══════════════════════════════════════════════════════"
    Write-Log "  Terraform Deployment — Environment: $Environment"
    Write-Log "═══════════════════════════════════════════════════════"

    # --- Prereqs ---
    Assert-Command "terraform"
    Assert-Command "az"

    $tfVersion = & terraform -version -json | ConvertFrom-Json
    Write-Log "Terraform version: $($tfVersion.terraform_version)"

    if (-not (Test-Path $VarFile)) {
        throw "Variable file not found: $VarFile"
    }
    Write-Log "Using var file: $VarFile"

    # --- Step 1: terraform init ---
    Write-Log "──── Step 1/4: terraform init ────"
    Invoke-Terraform -StepName "init" -Arguments @(
        "init",
        "-backend-config=resource_group_name=$BackendResourceGroup",
        "-backend-config=storage_account_name=$BackendStorageAccount",
        "-backend-config=container_name=$BackendContainer",
        "-backend-config=key=$BackendKey",
        "-input=false",
        "-no-color"
    )
    Write-Log "Init completed successfully."

    # --- Step 2: terraform plan ---
    Write-Log "──── Step 2/4: terraform plan ────"
    $planFile = Join-Path $LogDirectory "tfplan-${Environment}-${timestamp}"

    $planOutput = Invoke-Terraform -StepName "plan" -Arguments @(
        "plan",
        "-var-file=$VarFile",
        "-var=environment=$Environment",
        "-out=$planFile",
        "-input=false",
        "-no-color"
    )

    # Save readable plan output alongside the binary plan
    $planTextFile = "${planFile}.txt"
    $planOutput | Out-File -FilePath $planTextFile -Encoding utf8
    Write-Log "Plan saved to: $planFile"
    Write-Log "Plan text saved to: $planTextFile"

    # Display plan summary
    $summaryLine = ($planOutput -split "`n") | Where-Object { $_ -match "Plan:|No changes" } | Select-Object -Last 1
    if ($summaryLine) {
        Write-Log "Plan summary: $($summaryLine.Trim())"
    }

    # --- Step 3: Confirmation ---
    Write-Log "──── Step 3/4: Confirmation ────"
    if ($AutoApprove) {
        Write-Log "AutoApprove is set — skipping confirmation." -Level WARN
    }
    else {
        Write-Host ""
        Write-Host "Review the plan above. Proceed with apply?" -ForegroundColor Yellow
        $response = Read-Host "Type 'yes' to apply, anything else to abort"
        if ($response -ne "yes") {
            Write-Log "Operator aborted the deployment." -Level WARN
            Write-Host "Deployment aborted. No changes were made." -ForegroundColor Yellow
            exit 0
        }
        Write-Log "Operator confirmed apply."
    }

    # --- Step 4: terraform apply ---
    Write-Log "──── Step 4/4: terraform apply ────"
    Invoke-Terraform -StepName "apply" -Arguments @(
        "apply",
        "-input=false",
        "-no-color",
        $planFile
    )
    Write-Log "Apply completed successfully."

    # --- Capture outputs ---
    Write-Log "Capturing Terraform outputs..."
    $outputJson = & terraform output -json 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to capture Terraform outputs." -Level WARN
    }
    else {
        $outputFile = Join-Path $PSScriptRoot "deployment-output.json"
        $deploymentResult = @{
            metadata = @{
                environment  = $Environment
                deployed_at  = (Get-Date -Format "o")
                deployed_by  = $env:USERNAME
                terraform_version = $tfVersion.terraform_version
                plan_file    = $planFile
            }
            outputs = ($outputJson | ConvertFrom-Json)
        } | ConvertTo-Json -Depth 10

        $deploymentResult | Out-File -FilePath $outputFile -Encoding utf8
        Write-Log "Outputs written to: $outputFile"
    }

    # --- Clean up plan file ---
    if (Test-Path $planFile) {
        Remove-Item $planFile -Force
        Write-Log "Cleaned up binary plan file."
    }

    Write-Log "═══════════════════════════════════════════════════════"
    Write-Log "  Deployment SUCCEEDED — Environment: $Environment"
    Write-Log "═══════════════════════════════════════════════════════"
    exit 0
}
catch {
    Write-Log "Deployment FAILED: $_" -Level ERROR
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level ERROR
    Write-Log "═══════════════════════════════════════════════════════"
    Write-Log "  Deployment FAILED — Environment: $Environment" -Level ERROR
    Write-Log "═══════════════════════════════════════════════════════"
    Write-Log "See full log: $logFile" -Level ERROR
    exit 1
}
