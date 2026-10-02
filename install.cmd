@echo off
REM install.cmd - Double-click to install mdv (Markdown viewer) for the current user.
REM It downloads and runs install.ps1 from https://github.com/rothausen/mdv

echo Installing mdv...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; irm https://raw.githubusercontent.com/rothausen/mdv/main/install.ps1 | iex"
echo.
pause
