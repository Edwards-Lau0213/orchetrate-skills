[CmdletBinding()]
param(
    [string] $CodexSkillsRoot = (Join-Path $HOME ".codex\skills"),
    [string[]] $ExtraSkillsRoots = @(),
    [string] $OutputDir = (Join-Path (Get-Location) "generated"),
    [switch] $IncludeAbsolutePaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-RelativePath {
    param(
        [Parameter(Mandatory)] [string] $Root,
        [Parameter(Mandatory)] [string] $Path
    )

    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $pathFull.Substring($rootFull.Length).TrimStart('\', '/')
    }
    return $pathFull
}

function Get-FrontMatter {
    param([Parameter(Mandatory)] [string] $Text)

    if ($Text -match "(?ms)\A---\s*(.*?)\s*---") {
        return $matches[1]
    }
    return ""
}

function Get-FrontMatterValue {
    param(
        [Parameter(Mandatory)] [string] $FrontMatter,
        [Parameter(Mandatory)] [string] $Key
    )

    $escaped = [regex]::Escape($Key)
    if ($FrontMatter -match "(?ms)^$escaped\s*:\s*(.*?)(?=^\w[\w-]*\s*:|\z)") {
        $value = $matches[1].Trim()
        $value = $value -replace "^\|[-+]?\s*", ""
        $value = $value -replace "^>[-+]?\s*", ""
        $value = $value -replace "\s+", " "
        return $value.Trim(" `t`r`n""'")
    }
    return $null
}

function Get-SkillCategory {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $RelativePath
    )

    if ($Source -eq "Codex system") { return "System and authoring" }
    if ($Name -in @("orchestrate-skills")) { return "Skill orchestration and management" }
    if ($Name -like "gsap-*") { return "Frontend animation / GSAP" }
    if ($RelativePath -like "gstack\*" -or $Name -in @("qa", "qa-only", "review", "ship", "retro", "office-hours", "setup-deploy", "setup-browser-cookies", "unfreeze", "plan-ceo-review", "plan-design-review", "plan-eng-review")) {
        return "GStack product/dev workflow"
    }
    if ($Name -like "nature-*" -or $Name -like "paper-*" -or $Name -in @("overleaf-sync", "rebuttal", "resubmit-pipeline", "citation-audit", "paper-claim-audit", "writing-systems-papers", "grant-proposal", "nature-citation")) {
        return "Paper writing and submission"
    }
    if ($Name -like "research-*" -or $Name -like "idea-*" -or $Name -in @("novelty-check", "comm-lit-review", "auto-review-loop", "auto-review-loop-llm", "auto-review-loop-minimax", "auto-paper-improvement-loop")) {
        return "Research ideation and review"
    }
    if ($Name -like "experiment-*" -or $Name -in @("run-experiment", "monitor-experiment", "analyze-results", "result-to-claim", "ablation-planner", "dse-loop", "training-check", "system-profile", "serverless-modal", "vast-gpu", "qzcli")) {
        return "Experiment, compute, and profiling"
    }
    if ($Name -like "patent-*" -or $Name -in @("claims-drafting", "embodiment-description", "figure-description", "invention-structuring", "jurisdiction-format", "prior-art-search", "specification-writing")) {
        return "Patent and IP drafting"
    }
    if ($Name -in @("arxiv", "alphaxiv", "deepxiv", "semantic-scholar", "exa-search")) {
        return "Literature and web retrieval"
    }
    if ($Name -in @("doc", "pdf", "mermaid-diagram", "pixel-art", "figure-spec", "paper-figure", "paper-illustration", "imagegen")) {
        return "Documents, figures, and media"
    }
    if ($Name -in @("proof-checker", "proof-writer", "formula-derivation")) {
        return "Math and proof work"
    }
    if ($Name -in @("feishu-notify", "llm-wiki-maintainer", "meta-optimize", "karpathy-guidelines")) {
        return "Utilities and knowledge management"
    }
    return "Other"
}

function Get-SkillEntries {
    param(
        [Parameter(Mandatory)] [string] $Root,
        [Parameter(Mandatory)] [string] $Source
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        return @()
    }

    $files = Get-ChildItem -LiteralPath $Root -Recurse -Force -File -Filter "SKILL.md"
    foreach ($file in $files) {
        $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
        $normalizedText = $text -replace "`r`n", "`n"
        $frontMatter = Get-FrontMatter -Text $text
        $name = Get-FrontMatterValue -FrontMatter $frontMatter -Key "name"
        if ([string]::IsNullOrWhiteSpace($name)) {
            $name = Split-Path -Leaf $file.DirectoryName
        }
        $description = Get-FrontMatterValue -FrontMatter $frontMatter -Key "description"
        if ([string]::IsNullOrWhiteSpace($description)) {
            $description = ""
        }
        $license = Get-FrontMatterValue -FrontMatter $frontMatter -Key "license"
        $relativePath = ConvertTo-RelativePath -Root $Root -Path $file.FullName
        if ($Source -eq "Codex installed" -and $relativePath -like ".system\*") {
            $entrySource = "Codex system"
        }
        else {
            $entrySource = $Source
        }
        $entry = [pscustomobject]@{
            Name = $name
            Category = Get-SkillCategory -Name $name -Source $entrySource -RelativePath $relativePath
            Source = $entrySource
            RelativePath = $relativePath
            Description = $description
            License = $license
            Bytes = $file.Length
            NormalizedContentSha256 = Get-TextSha256 -Text $normalizedText
            LastWriteTime = $file.LastWriteTime.ToString("s")
        }
        if ($IncludeAbsolutePaths) {
            $entry | Add-Member -NotePropertyName Root -NotePropertyValue ([System.IO.Path]::GetFullPath($Root))
            $entry | Add-Member -NotePropertyName FullPath -NotePropertyValue $file.FullName
        }
        $entry
    }
}

function Escape-MarkdownCell {
    param([AllowNull()] [string] $Value)

    if ($null -eq $Value) { return "" }
    return ($Value -replace "\|", "\|") -replace "`r?`n", " "
}

function Shorten {
    param(
        [AllowNull()] [string] $Value,
        [int] $MaxLength = 150
    )

    if ($null -eq $Value) { return "" }
    $oneLine = $Value -replace "\s+", " "
    if ($oneLine.Length -le $MaxLength) { return $oneLine }
    return $oneLine.Substring(0, $MaxLength - 3) + "..."
}

function Get-TextSha256 {
    param([Parameter(Mandatory)] [string] $Text)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hash = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($Path), $Content, $encoding)
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$entries = @()
$entries += Get-SkillEntries -Root $CodexSkillsRoot -Source "Codex installed"
foreach ($extraRoot in $ExtraSkillsRoots) {
    if ([string]::IsNullOrWhiteSpace($extraRoot)) {
        continue
    }
    $sourceName = "Extra: $(Split-Path -Leaf ([System.IO.Path]::GetFullPath($extraRoot).TrimEnd('\', '/')))"
    $entries += Get-SkillEntries -Root $extraRoot -Source $sourceName
}
$entries = $entries | Sort-Object Source, Category, Name, RelativePath

$jsonPath = Join-Path $OutputDir "skills-inventory.json"
$mdPath = Join-Path $OutputDir "skills-inventory.md"
$jsonText = $entries | ConvertTo-Json -Depth 5
Write-Utf8NoBom -Path $jsonPath -Content $jsonText

$sourceSummary = @($entries | Group-Object Source | Sort-Object Name)
$categorySummary = @($entries | Group-Object Category | Sort-Object Name)
$duplicates = @($entries | Group-Object Name | Where-Object { $_.Count -gt 1 } | Sort-Object Name)

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Skills Inventory")
$lines.Add("")
$lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')")
$lines.Add("")
$lines.Add("## Source Summary")
$lines.Add("")
$lines.Add("| Source | Count |")
$lines.Add("|---|---:|")
foreach ($group in $sourceSummary) {
    $lines.Add("| $(Escape-MarkdownCell $group.Name) | $($group.Count) |")
}
$lines.Add("")
$lines.Add("## Category Summary")
$lines.Add("")
$lines.Add("| Category | Count |")
$lines.Add("|---|---:|")
foreach ($group in $categorySummary) {
    $lines.Add("| $(Escape-MarkdownCell $group.Name) | $($group.Count) |")
}
$lines.Add("")
$lines.Add("## Management Notes")
$lines.Add("")
$lines.Add("- Codex installed is the active runtime set. Keep only globally useful Skills there.")
$lines.Add("- Repo-local Skills should normally stay with their owning repository unless they are intentionally promoted to global use.")
$lines.Add("- Third-party source checkouts should be passed through `-ExtraSkillsRoots` only when you want them included in a local inventory report.")
$lines.Add("- Codex system Skills are bundled authoring/runtime helpers. Treat them as read-only unless intentionally customizing Codex itself.")
$lines.Add("")
$lines.Add("## Duplicate Names")
$lines.Add("")
if ($duplicates.Count -eq 0) {
    $lines.Add("No duplicate skill names across tracked sources.")
}
else {
    $lines.Add("| Name | Count | Content variants | Sources | Paths |")
    $lines.Add("|---|---:|---:|---|---|")
    foreach ($group in $duplicates) {
        $sources = ($group.Group | Select-Object -ExpandProperty Source -Unique) -join ", "
        $variantCount = @($group.Group | Select-Object -ExpandProperty NormalizedContentSha256 -Unique).Count
        $paths = ($group.Group | ForEach-Object { "$($_.Source): $($_.RelativePath)" }) -join "<br>"
        $lines.Add("| $(Escape-MarkdownCell $group.Name) | $($group.Count) | $variantCount | $(Escape-MarkdownCell $sources) | $(Escape-MarkdownCell $paths) |")
    }
}
$lines.Add("")
$lines.Add("## Full Inventory")
$lines.Add("")
$lines.Add("| Name | Category | Source | Path | Description |")
$lines.Add("|---|---|---|---|---|")
foreach ($entry in $entries) {
    $path = Escape-MarkdownCell $entry.RelativePath
    $lines.Add("| $(Escape-MarkdownCell $entry.Name) | $(Escape-MarkdownCell $entry.Category) | $(Escape-MarkdownCell $entry.Source) | $path | $(Escape-MarkdownCell (Shorten $entry.Description)) |")
}

$mdText = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
Write-Utf8NoBom -Path $mdPath -Content $mdText

Write-Host "Wrote $mdPath"
Write-Host "Wrote $jsonPath"
Write-Host "Total skills: $($entries.Count)"
