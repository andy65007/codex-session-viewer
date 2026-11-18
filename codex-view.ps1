[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("assistant", "activity", "user", "all")]
    [string]$Mode = "assistant",

    [Parameter(Position = 1)]
    [string]$Path,

    [string]$Output,

    [switch]$Open
)

$ErrorActionPreference = "Stop"

function Find-CodexExport {
    param([string]$Directory)

    $candidate = Get-ChildItem -LiteralPath $Directory -File -Filter "codex-session-*.md" |
        Where-Object { $_.Name -notmatch "\.(assistant|activity|user|all)\.md$" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $candidate) {
        throw "No Codex export named codex-session-*.md was found in: $Directory"
    }

    return $candidate
}

if ([string]::IsNullOrWhiteSpace($Path)) {
    $inputFile = Find-CodexExport -Directory $PSScriptRoot
}
else {
    $pathItem = Get-Item -LiteralPath $Path
    if ($pathItem.PSIsContainer) {
        $inputFile = Find-CodexExport -Directory $pathItem.FullName
    }
    else {
        $inputFile = $pathItem
    }
}

$inputFile = Get-Item -LiteralPath $inputFile.FullName

if ([string]::IsNullOrWhiteSpace($Output)) {
    $baseName = [IO.Path]::GetFileNameWithoutExtension($inputFile.Name)
    $Output = Join-Path $inputFile.DirectoryName "$baseName.$($Mode.ToLowerInvariant()).md"
}
elseif (-not [IO.Path]::IsPathRooted($Output)) {
    $Output = Join-Path (Get-Location) $Output
}

$Output = [IO.Path]::GetFullPath($Output)
if ($Output -eq $inputFile.FullName) {
    throw "Refusing to overwrite the original export. Choose another output path."
}

$lines = [IO.File]::ReadAllLines($inputFile.FullName)
$filtered = [Collections.Generic.List[string]]::new()
$currentRole = "Preamble"
$inFence = $false
$fenceCharacter = $null
$fenceLength = 0

foreach ($line in $lines) {
    $isRoleHeading = $false

    if (-not $inFence -and $line -match "^##[ \t]+(User|Assistant|Activity)[ \t]*$") {
        $currentRole = $Matches[1]
        $isRoleHeading = $true
    }

    $include = switch ($Mode.ToLowerInvariant()) {
        "assistant" { $currentRole -in @("Preamble", "User", "Assistant") }
        "activity" { $currentRole -in @("Preamble", "Activity") }
        "user" { $currentRole -in @("Preamble", "User") }
        "all" { $true }
    }

    if ($include) {
        $filtered.Add($line)
    }

    if (-not $isRoleHeading) {
        if (-not $inFence -and $line -match '^( {0,3})(`{3,}|~{3,})') {
            $inFence = $true
            $fenceCharacter = $Matches[2][0]
            $fenceLength = $Matches[2].Length
        }
        elseif ($inFence) {
            $marker = [regex]::Escape([string]$fenceCharacter)
            $closingPattern = "^( {0,3})$marker{$fenceLength,}[ \t]*$"
            if ($line -match $closingPattern) {
                $inFence = $false
                $fenceCharacter = $null
                $fenceLength = 0
            }
        }
    }
}

$outputDirectory = [IO.Path]::GetDirectoryName($Output)
if (-not [IO.Directory]::Exists($outputDirectory)) {
    [IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
}

$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllLines($Output, $filtered.ToArray(), $utf8NoBom)

Write-Host "Created $Mode view: $Output"

if ($Open) {
    $codeCommand = Get-Command code -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -ne $codeCommand) {
        Start-Process -FilePath $codeCommand.Source -ArgumentList @("--reuse-window", $Output)
    }
    else {
        Invoke-Item -LiteralPath $Output
    }
}
