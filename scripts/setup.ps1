$RootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

New-Item -ItemType Junction -Path (Join-Path $env:LOCALAPPDATA 'nvim') `
         -Target (Join-Path $RootDir 'nvim')
