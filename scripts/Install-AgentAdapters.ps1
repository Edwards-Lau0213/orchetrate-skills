[CmdletBinding()]
param(
    [ValidateSet("Codex", "Claude", "ProjectAdapters", "All")]
    [string[]] $Targets = @("All"),
    [string] $ProjectRoot = (Get-Location),
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillSource = Join-Path $repoRoot "skills\orchestrate-skills"

function Copy-DirectoryClean {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Missing source: $Source"
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Copy-FileCreatingParent {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination
    )

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
        Write-Host "Skipped existing file: $Destination"
        return
    }
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
            Write-Host "Installed Codex Skill: $destination"
        }
        "Claude" {
            $destination = Join-Path $HOME ".claude\skills\orchestrate-skills"
            Copy-DirectoryClean -Source $skillSource -Destination $destination
            Write-Host "Installed Claude Code Skill: $destination"
        }
        "ProjectAdapters" {
            $projectFull = [System.IO.Path]::GetFullPath($ProjectRoot)
            Copy-FileCreatingParent -Source (Join-Path $repoRoot "AGENTS.md") -Destination (Join-Path $projectFull "AGENTS.md")
            Copy-FileCreatingParent -Source (Join-Path $repoRoot "CLAUDE.md") -Destination (Join-Path $projectFull "CLAUDE.md")
            Copy-FileCreatingParent -Source (Join-Path $repoRoot ".cursor\rules\orchestrate-skills.mdc") -Destination (Join-Path $projectFull ".cursor\rules\orchestrate-skills.mdc")
            Copy-FileCreatingParent -Source (Join-Path $repoRoot ".github\copilot-instructions.md") -Destination (Join-Path $projectFull ".github\copilot-instructions.md")
            Write-Host "Installed project adapters: $projectFull"
        }
    }
}
