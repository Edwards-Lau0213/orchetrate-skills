[CmdletBinding()]
param(
    [ValidateSet("Codex", "Claude", "ProjectAdapters", "All")]
    [string[]] $Targets = @("All"),
    [string] $ProjectRoot = (Get-Location),
    [string] $BackupRoot = (Join-Path $HOME ".codex\skill-backups"),
    [switch] $Force,
    [switch] $DryRun,
    [switch] $Check,
    [switch] $Backup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillSource = Join-Path $repoRoot "skills\orchestrate-skills"
$backupStamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Write-Action {
    param([Parameter(Mandatory)] [string] $Message)

    if ($DryRun -or $Check) {
        Write-Host "Would: $Message"
    }
    else {
        Write-Host $Message
    }
}

function New-BackupPath {
    param([Parameter(Mandatory)] [string] $Path)

    $leaf = Split-Path -Leaf $Path
    return (Join-Path $BackupRoot "$leaf.backup-$backupStamp")
}

function Backup-ExistingPath {
    param([Parameter(Mandatory)] [string] $Path)

    if (-not $Backup -or -not (Test-Path -LiteralPath $Path)) {
        return
    }

    $backupPath = New-BackupPath -Path $Path
    if ($DryRun) {
        Write-Host "Would backup $Path -> $backupPath"
        return
    }

    New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    Copy-Item -LiteralPath $Path -Destination $backupPath -Recurse -Force
    Write-Host "Backed up $Path -> $backupPath"
}

function Test-PathStatus {
    param([Parameter(Mandatory)] [string] $Path)

    if (Test-Path -LiteralPath $Path) {
        Write-Host "OK: $Path"
        return $true
    }
    Write-Host "Missing: $Path"
    return $false
}

function Copy-DirectoryClean {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Missing source: $Source"
    }
    if ($Check) {
        Test-PathStatus -Path $Destination | Out-Null
        return
    }

    if (Test-Path -LiteralPath $Destination) {
        Backup-ExistingPath -Path $Destination
        if ($DryRun) {
            Write-Action "replace directory $Destination from $Source"
            return
        }
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    if ($DryRun) {
        Write-Action "copy directory $Source -> $Destination"
        return
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Copy-FileCreatingParent {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination
    )

    if ($Check) {
        Test-PathStatus -Path $Destination | Out-Null
        return
    }

    if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
        Write-Host "Skipped existing file: $Destination"
        return
    }
    Backup-ExistingPath -Path $Destination
    if ($DryRun) {
        Write-Action "copy file $Source -> $Destination"
        return
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

$expandedTargets = if ($Targets -contains "All") {
    @("Codex", "Claude", "ProjectAdapters")
}
else {
    $Targets
}

foreach ($target in $expandedTargets) {
    switch ($target) {
        "Codex" {
            $destination = Join-Path $HOME ".codex\skills\orchestrate-skills"
            Copy-DirectoryClean -Source $skillSource -Destination $destination
            if (-not $Check -and -not $DryRun) {
                Write-Host "Installed Codex Skill: $destination"
            }
        }
        "Claude" {
            $destination = Join-Path $HOME ".claude\skills\orchestrate-skills"
            Copy-DirectoryClean -Source $skillSource -Destination $destination
            if (-not $Check -and -not $DryRun) {
                Write-Host "Installed Claude Code Skill: $destination"
            }
        }
        "ProjectAdapters" {
            $projectFull = [System.IO.Path]::GetFullPath($ProjectRoot)
            Copy-FileCreatingParent -Source (Join-Path $repoRoot "AGENTS.md") -Destination (Join-Path $projectFull "AGENTS.md")
            Copy-FileCreatingParent -Source (Join-Path $repoRoot "CLAUDE.md") -Destination (Join-Path $projectFull "CLAUDE.md")
            Copy-FileCreatingParent -Source (Join-Path $repoRoot ".cursor\rules\orchestrate-skills.mdc") -Destination (Join-Path $projectFull ".cursor\rules\orchestrate-skills.mdc")
            Copy-FileCreatingParent -Source (Join-Path $repoRoot ".github\copilot-instructions.md") -Destination (Join-Path $projectFull ".github\copilot-instructions.md")
            if (-not $Check -and -not $DryRun) {
                Write-Host "Installed project adapters: $projectFull"
            }
        }
    }
}
