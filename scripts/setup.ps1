# Link this repository's configuration into its Windows locations: a junction
# at %LOCALAPPDATA%\nvim for Neovim, file links for the PowerShell 7 profile in
# Documents\PowerShell, and junctions for the skills in %USERPROFILE% (no
# Administrator rights needed).
[CmdletBinding()]
param(
    # Replace an existing target: a foreign link is removed, a real file or
    # directory is backed up to <target>.bak.<timestamp>.
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host $Message -ForegroundColor Green }
function Write-Hint { param([string]$Message) Write-Host "  -> $Message" -ForegroundColor Cyan }

# Install-ScoopPackage <package> <command>: install <package> with Scoop when
# <command> is missing; only warns when Scoop itself is unavailable.
function Install-ScoopPackage {
    param([string]$Package, [string]$Command)
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Info "Found: $Command"
        return $true
    }
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Info "Installing $Package with Scoop..."
        scoop install $Package
        if ($LASTEXITCODE -eq 0) { return $true }
        Write-Warning "scoop install $Package failed; install it manually."
    } else {
        Write-Warning "$Command is not installed and Scoop was not found."
        Write-Hint "Install Scoop first (https://scoop.sh), then: scoop install $Package"
    }
    return $false
}

# Get-ChildItem on the parent sees the entry itself, so this also catches
# broken links that Test-Path/Get-Item would silently miss.
function Get-ExistingEntry {
    param([string]$Path)
    $Parent = Split-Path $Path
    if (-not (Test-Path $Parent -PathType Container)) { return $null }
    Get-ChildItem -Force -Path $Parent -Filter (Split-Path $Path -Leaf) `
        -ErrorAction SilentlyContinue
}

# A hard link is not a reparse point, so its LinkType stays empty; equal content
# is what identifies it as already pointing at the source.
function Test-SameContent {
    param([string]$Path, [string]$Source)
    if (-not (Test-Path $Path -PathType Leaf)) { return $false }
    (Get-FileHash -Path $Path).Hash -eq (Get-FileHash -Path $Source).Hash
}

function Test-LinkedTo {
    param([string]$Path, [string]$Source)
    $Existing = Get-ExistingEntry -Path $Path
    if (-not $Existing) { return $false }
    if ($Existing.LinkType) { return ($Existing.Target -contains $Source) }
    return (Test-SameContent -Path $Path -Source $Source)
}

# New-ConfigLink <source> <target> <link types>: link <target> to <source>,
# trying each link type in order. Returns $true when the target points at the
# source afterwards, whether it was linked now or by an earlier run.
function New-ConfigLink {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string[]]$LinkType
    )

    if (-not (Test-Path $Source)) {
        Write-Warning "expected source not found: $Source"
        Write-Hint 'run this script from a full clone of the dotfiles repository.'
        return $false
    }

    $Existing = Get-ExistingEntry -Path $Target
    if ($Existing) {
        if (Test-LinkedTo -Path $Target -Source $Source) {
            Write-Info "Skipped: $Target already points to $Source."
            return $true
        }
        if (-not $Force) {
            if ($Existing.LinkType) {
                $LinkTarget = @($Existing.Target) -join '; '
                Write-Warning "$Target is a link to $LinkTarget, not to this repository."
            } else {
                Write-Warning "$Target already exists."
            }
            Write-Hint 'Back it up or remove it yourself, or re-run with -Force to replace it.'
            return $false
        }
        if ($Existing.LinkType) {
            $LinkTarget = @($Existing.Target) -join '; '
            $Existing.Delete()  # removes the link only, never its target
            Write-Info "Removed old link: $Target -> $LinkTarget"
        } else {
            $Backup = "$Target.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item -Path $Target -Destination $Backup
            Write-Info "Backed up existing config: $Backup"
        }
    }

    $Parent = Split-Path $Target
    if (-not (Test-Path $Parent -PathType Container)) {
        New-Item -ItemType Directory -Path $Parent -Force | Out-Null
        Write-Info "Created directory: $Parent"
    }

    foreach ($Type in $LinkType) {
        try {
            New-Item -ItemType $Type -Path $Target -Target $Source -ErrorAction Stop | Out-Null
            Write-Info "Linked: $Target -> $Source ($Type)"
            return $true
        } catch {
            Write-Hint "$Type is not available here: $($_.Exception.Message)"
        }
    }

    Write-Warning "could not link $Target"
    Write-Hint 'enable Developer Mode for symbolic links, or copy the files manually.'
    return $false
}

# --- Environment checks -----------------------------------------------------

$MissingDeps = $false

$Nvim = Get-Command nvim -ErrorAction SilentlyContinue
if (-not $Nvim) {
    Write-Warning 'Neovim is not installed or not on PATH.'
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Hint 'Install it with: scoop install neovim'
    } else {
        Write-Hint 'Install it with: winget install Neovim.Neovim'
    }
} else {
    # This configuration relies on Neovim 0.11+ (vim.lsp auto-discovery).
    $VersionLine = & nvim --version | Select-Object -First 1
    if ($VersionLine -match 'NVIM v(\d+)\.(\d+)') {
        if ([int]$Matches[1] -eq 0 -and [int]$Matches[2] -lt 11) {
            Write-Warning "Neovim $($Matches[0]) detected; this configuration requires Neovim 0.11 or newer."
        }
    }
}

# --- nvim-treesitter external dependencies ----------------------------------
# The configuration uses the main-branch nvim-treesitter, which shells out to
# the tree-sitter CLI and a C compiler (vim.env.CC = "gcc") to build parsers.
# Missing pieces are installed with Scoop when it is available.

if (-not (Install-ScoopPackage 'tree-sitter' 'tree-sitter')) { $MissingDeps = $true }
if (-not (Install-ScoopPackage 'gcc' 'gcc')) { $MissingDeps = $true }

# --- Link targets -----------------------------------------------------------

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$PowerShellDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell'

$Links = @(
    @{
        Source   = Join-Path $RootDir '.config/nvim'
        Target   = Join-Path $env:LOCALAPPDATA 'nvim'
        LinkType = @('Junction')
    }
    @{
        Source   = Join-Path $RootDir '.config/powershell/Microsoft.PowerShell_profile.ps1'
        Target   = Join-Path $PowerShellDir 'Microsoft.PowerShell_profile.ps1'
        LinkType = @('HardLink', 'SymbolicLink')
    }
    @{
        Source   = Join-Path $RootDir '.config/powershell/powershell.config.json'
        Target   = Join-Path $PowerShellDir 'powershell.config.json'
        LinkType = @('HardLink', 'SymbolicLink')
    }
    @{
        Source   = Join-Path $RootDir '.agents/skills'
        Target   = Join-Path $env:USERPROFILE '.agents/skills'
        LinkType = @('Junction')
    }
    @{
        Source   = Join-Path $RootDir '.agents/skills'
        Target   = Join-Path $env:USERPROFILE '.claude/skills'
        LinkType = @('Junction')
    }
)

# --- Create the links --------------------------------------------------------

$Failed = $false
foreach ($Link in $Links) {
    if (-not (New-ConfigLink @Link)) { $Failed = $true }
}

if ($Failed) { exit 1 }

if ($MissingDeps) {
    Write-Warning 'some dependencies are still missing; fix the items above, then run :TSUpdate inside Neovim.'
}
