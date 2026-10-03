$RootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Target = Join-Path $env:LOCALAPPDATA 'nvim'

# Get-ChildItem on the parent sees the entry itself, so this also catches
# broken links that Test-Path/Get-Item would silently miss.
$Existing = Get-ChildItem -Force -Path (Split-Path $Target) `
            -Filter (Split-Path $Target -Leaf) -ErrorAction SilentlyContinue

if ($Existing) {
    if ($Existing.LinkType) {
        Write-Host "Skipped: $Target is already a link."
        exit 0
    }
    Write-Warning "$Target already exists. Back it up or remove it yourself, then re-run this script."
    exit 1
}

New-Item -ItemType Junction -Path $Target -Target (Join-Path $RootDir 'nvim')
