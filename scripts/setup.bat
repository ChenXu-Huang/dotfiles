@echo off
chcp 65001 >nul
setlocal

set "ROOT_DIR=%~dp0.."

mklink /d "%LOCALAPPDATA%\nvim" "%ROOT_DIR%\nvim"

endlocal
