# Link this repository's nvim/ directory into Neovim's config location.
# Creates a junction at %LOCALAPPDATA%\nvim (no Administrator rights needed).
[CmdletBinding()]
param(
    # Replace an existing target: a foreign link is removed, a real file or
    # directory is backed up to nvim.bak.<timestamp>.
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

# --- Resolve paths ----------------------------------------------------------

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Source = Join-Path $RootDir 'nvim'
$Target = Join-Path $env:LOCALAPPDATA 'nvim'

if (-not (Test-Path $Source -PathType Container)) {
    Write-Error "expected nvim/ directory not found at $Source"
    exit 1
}

# --- Handle an existing target ----------------------------------------------

# Get-ChildItem on the parent sees the entry itself, so this also catches
# broken links that Test-Path/Get-Item would silently miss.
$Existing = Get-ChildItem -Force -Path (Split-Path $Target) `
            -Filter (Split-Path $Target -Leaf) -ErrorAction SilentlyContinue

if ($Existing) {
    if ($Existing.LinkType) {
        $LinkTarget = @($Existing.Target) -join '; '
        if ($Existing.Target -contains $Source) {
            Write-Info "Skipped: $Target already points to $Source."
            exit 0
        }
        if ($Force) {
            $Existing.Delete()  # removes the link only, never its target
            Write-Info "Removed old link: $Target -> $LinkTarget"
        } else {
            Write-Warning "$Target is a link to $LinkTarget, not to this repository."
            Write-Hint 'Re-run with -Force to replace it, or remove it yourself.'
            exit 1
        }
    } else {
        if ($Force) {
            $Backup = "$Target.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item -Path $Target -Destination $Backup
            Write-Info "Backed up existing config: $Backup"
        } else {
            Write-Warning "$Target already exists."
            Write-Hint 'Back it up or remove it yourself, or re-run with -Force to back it up automatically.'
            exit 1
        }
    }
}

# --- Create the link ---------------------------------------------------------

New-Item -ItemType Junction -Path $Target -Target $Source | Out-Null
Write-Info "Linked: $Target -> $Source"

if ($MissingDeps) {
    Write-Warning 'some dependencies are still missing; fix the items above, then run :TSUpdate inside Neovim.'
}
