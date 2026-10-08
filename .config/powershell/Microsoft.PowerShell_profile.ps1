# UTF-8 charset
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# Hook scoop-search
if (Get-Command scoop-search -ErrorAction SilentlyContinue) {
    . ([ScriptBlock]::Create((& scoop-search --hook | Out-String)))
}

# Load oh-my-posh
Import-Module posh-git
oh-my-posh init pwsh --config 'stelbent.minimal' | Invoke-Expression
Import-Module -Name Terminal-Icons

# PSReadLine
Set-PSReadLineOption -Editmode Emacs
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -Colors @{ InlinePrediction = '#8A8A8A' }
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# PSFzf
Import-Module PSFzf
Set-PSFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Alias
Set-Alias -Name vim -Value nvim
Set-Alias g git
function grep { $input | findstr $args }
function which { Get-Command @args -ErrorAction SilentlyContinue | % Source }

# Paths
$kitsRoot = (Get-ItemProperty 'HKLM:SOFTWARE\Microsoft\Windows Kits\Installed Roots' -ErrorAction SilentlyContinue).KitsRoot10
if ($kitsRoot) {
    $sdkBin = Get-ChildItem (Join-Path $kitsRoot 'bin') -Directory -ErrorAction SilentlyContinue |
              Where-Object { Test-Path (Join-Path $_.FullName 'x64') } |
              Sort-Object { [version]$_.Name } -Descending |
              Select-Object -First 1
    if ($sdkBin) { $env:PATH += (Join-Path $sdkBin.FullName 'x64') + ';' }
}
