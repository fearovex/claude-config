<#
.SYNOPSIS
    Deploys SDD prompt/agent templates to a target project's .github/ folder.

.DESCRIPTION
    Copies the generic SDD Copilot templates (prompts + agent) from this
    agent-config repository into the .github/ structure of any target project.

    The three .instructions.md files are NOT copied — those are project-specific
    and should be generated with /config-export in the target project.

.PARAMETER TargetPath
    Absolute path to the root of the target project.

.EXAMPLE
    .\scripts\init-copilot-sdd.ps1 -TargetPath "D:\Proyectos\MyProject"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Resolve paths
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot    = Split-Path -Parent $scriptDir
$templateDir = Join-Path $repoRoot "docs\copilot-templates\sdd"

# Validate template source
if (-not (Test-Path $templateDir)) {
    Write-Error "Template directory not found: $templateDir"
    exit 1
}

# Validate target
if (-not (Test-Path $TargetPath)) {
    Write-Error "Target project path not found: $TargetPath"
    exit 1
}

$targetGithub  = Join-Path $TargetPath ".github"
$targetPrompts = Join-Path $targetGithub "prompts"
$targetAgents  = Join-Path $targetGithub "agents"

# Show plan
Write-Host ""
Write-Host "SDD Copilot Templates - Deploy Plan" -ForegroundColor Cyan
Write-Host "------------------------------------"
Write-Host "Source : $templateDir"
Write-Host "Target : $targetGithub"
Write-Host ""

$promptFiles = Get-ChildItem (Join-Path $templateDir "prompts") -Filter "*.md"
$agentFiles  = Get-ChildItem (Join-Path $templateDir "agents")  -Filter "*.md"

Write-Host "Files to deploy:"
foreach ($f in $promptFiles) { Write-Host "  .github/prompts/$($f.Name)" -ForegroundColor Yellow }
foreach ($f in $agentFiles)  { Write-Host "  .github/agents/$($f.Name)"  -ForegroundColor Yellow }
Write-Host ""

# Confirm
if (-not $Force) {
    Write-Host "Proceed? [y/N]: " -NoNewline
    $confirm = [Console]::ReadLine()
    if ($confirm -ne "y") {
        Write-Host "Cancelled - no files written." -ForegroundColor Gray
        exit 0
    }
}

# Create directories
New-Item -ItemType Directory -Force -Path $targetPrompts | Out-Null
New-Item -ItemType Directory -Force -Path $targetAgents  | Out-Null

# Copy prompts
foreach ($f in $promptFiles) {
    $dest = Join-Path $targetPrompts $f.Name
    Copy-Item $f.FullName $dest -Force
    Write-Host "  + $($f.Name)" -ForegroundColor Green
}

# Copy agents
foreach ($f in $agentFiles) {
    $dest = Join-Path $targetAgents $f.Name
    Copy-Item $f.FullName $dest -Force
    Write-Host "  + $($f.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done! SDD templates deployed to $targetGithub" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps in the target project:" -ForegroundColor Cyan
Write-Host "  1. Run /config-export to generate .github/copilot-instructions.md"
Write-Host "  2. Create .github/instructions/*.instructions.md for your stack"
Write-Host "  3. Open Copilot chat → select 'SDD Orchestrator' mode"
Write-Host ""
