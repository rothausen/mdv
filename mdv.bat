@echo off
REM mdv.bat - Render a Markdown file as a styled HTML page in your browser.
REM Usage: mdv C:\path\to\file.md
REM Tip: set this file as the default app for .md files to open them by double-click.

if "%~1"=="" (
    echo Usage: mdv ^<file.md^>
    pause
    exit /b 1
)

where py >nul 2>nul
if %errorlevel%==0 (
    py "%~dp0mdv.py" "%~1"
) else (
    python "%~dp0mdv.py" "%~1"
)

REM Keep the window open on errors so the message can be read.
if errorlevel 1 pause
