# install.ps1 - Install mdv (Markdown viewer) for the current Windows user.
#
# Double-click install.cmd, or run from PowerShell:
#   irm https://raw.githubusercontent.com/rothausen/mdv/main/install.ps1 | iex
#
# What it does:
#   1. Downloads mdv.py, mdv.bat and the icon mdv.ico to %USERPROFILE%\bin\mdv
#   2. Installs the Python packages mdv needs (markdown, pygments)
#   3. Registers mdv as a handler for .md and .markdown files, with its icon,
#      and as an app under Settings > Apps > Default apps
#   4. Adds the folder to your user PATH so "mdv file.md" works in a terminal
#   5. Opens the Settings page where you make mdv the default app
#
# Everything is per-user. No administrator rights are needed.

function Install-Mdv {
    if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
        Write-Host 'This installer is for Windows. On macOS and Linux, see the README.' -ForegroundColor Yellow
        return
    }

    $repoUrl    = 'https://raw.githubusercontent.com/rothausen/mdv/main'
    $installDir = Join-Path $env:USERPROFILE 'bin\mdv'
    $batPath    = Join-Path $installDir 'mdv.bat'
    $iconPath   = Join-Path $installDir 'mdv.ico'
    $logoPath   = Join-Path $installDir 'logo.png'
    $extensions = @('.md', '.markdown')

    # GitHub requires TLS 1.2, which older Windows PowerShell does not enable by default.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    # 1. Find a working Python 3.8+ (same order as mdv.bat: py first, then python).
    Write-Host 'Looking for Python...'
    $python = $null
    foreach ($candidate in @('py', 'python')) {
        if (-not (Get-Command $candidate -ErrorAction SilentlyContinue)) { continue }
        try {
            $out = & $candidate -c "import sys; print('%d.%d' % sys.version_info[:2])" 2>$null
            if ($LASTEXITCODE -ne 0) { continue }
            $version = [version](@($out)[-1])
        } catch {
            continue
        }
        if ($version -ge [version]'3.8') {
            $python = $candidate
            Write-Host "  Found Python $version ($candidate)"
            break
        }
    }
    if (-not $python) {
        Write-Host 'Python 3.8 or newer was not found. Install it, open a new PowerShell window and run this installer again:' -ForegroundColor Red
        Write-Host '  winget install Python.Python.3.13'
        return
    }

    $ErrorActionPreference = 'Stop'

    # 2. Download mdv.
    Write-Host "Downloading mdv to $installDir..."
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/mdv.py" -OutFile (Join-Path $installDir 'mdv.py')
    # Batch files need Windows line endings, whatever the repository stores.
    $bat = (Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/mdv.bat").Content
    if ($bat -is [byte[]]) { $bat = [Text.Encoding]::UTF8.GetString($bat) }
    $bat = $bat -replace "`r?`n", "`r`n"
    [IO.File]::WriteAllText($batPath, $bat, (New-Object Text.UTF8Encoding $false))
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/mdv.ico" -OutFile $iconPath
    } catch {
        Write-Host '  Could not download the icon. mdv works without it.' -ForegroundColor Yellow
        $iconPath = $null
    }
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "$repoUrl/logo.png" -OutFile $logoPath
    } catch {
        $logoPath = $null
    }

    # 3. Install the Python packages.
    Write-Host 'Installing Python packages (markdown, pygments)...'
    & $python -m pip install --quiet --disable-pip-version-check --no-warn-script-location --upgrade 'markdown>=3.3' 'pygments>=2.10'
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Package installation failed. See the pip output above.' -ForegroundColor Red
        return
    }

    # 4. Register mdv with Windows. Existing keys are reused, never wiped.
    Write-Host 'Registering mdv with Windows...'
    function Use-Key($path) {
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        $path
    }
    $classes = 'HKCU:\Software\Classes'
    $command = "`"$batPath`" `"%1`""
    $progId  = 'mdv.MarkdownFile'

    # A file type (ProgID) for Markdown files opened with mdv. Explorer takes the
    # file icon from here, and it lets Windows offer mdv as a default app.
    $progKey = "$classes\$progId"
    Set-ItemProperty -Path (Use-Key $progKey) -Name '(default)' -Value 'Markdown file'
    Set-ItemProperty -Path $progKey -Name 'FriendlyTypeName' -Value 'Markdown file'
    Set-ItemProperty -Path (Use-Key "$progKey\shell\open\command") -Name '(default)' -Value $command
    $appInfo = Use-Key "$progKey\Application"
    Set-ItemProperty -Path $appInfo -Name 'ApplicationName' -Value 'mdv'
    Set-ItemProperty -Path $appInfo -Name 'ApplicationDescription' -Value 'Read Markdown files as styled pages in your browser'
    if ($iconPath) {
        Set-ItemProperty -Path (Use-Key "$progKey\DefaultIcon") -Name '(default)' -Value $iconPath
        Set-ItemProperty -Path $appInfo -Name 'ApplicationIcon' -Value $iconPath
    }

    # The app entry used when someone picks mdv.bat by hand ("Choose an app on your PC").
    $appKey = "$classes\Applications\mdv.bat"
    Set-ItemProperty -Path (Use-Key "$appKey\shell\open\command") -Name '(default)' -Value $command
    Set-ItemProperty -Path $appKey -Name 'FriendlyAppName' -Value 'mdv'
    if ($iconPath) {
        Set-ItemProperty -Path (Use-Key "$appKey\DefaultIcon") -Name '(default)' -Value $iconPath
    }

    foreach ($ext in $extensions) {
        Set-ItemProperty -Path (Use-Key "$classes\$ext\OpenWithProgids") -Name $progId -Value ''
        # Older versions of this installer added mdv here too, which showed it twice.
        $oldEntry = "$classes\$ext\OpenWithList\mdv.bat"
        if (Test-Path $oldEntry) { Remove-Item -Path $oldEntry -Recurse }
    }

    # An app entry under Settings > Apps > Default apps.
    $capKey = 'HKCU:\Software\mdv\Capabilities'
    Set-ItemProperty -Path (Use-Key $capKey) -Name 'ApplicationName' -Value 'mdv'
    Set-ItemProperty -Path $capKey -Name 'ApplicationDescription' -Value 'Read Markdown files as styled pages in your browser'
    if ($iconPath) { Set-ItemProperty -Path $capKey -Name 'ApplicationIcon' -Value $iconPath }
    $assocKey = Use-Key "$capKey\FileAssociations"
    foreach ($ext in $extensions) { Set-ItemProperty -Path $assocKey -Name $ext -Value $progId }
    Set-ItemProperty -Path (Use-Key 'HKCU:\Software\RegisteredApplications') -Name 'mdv' -Value 'Software\mdv\Capabilities'

    # Tell Explorer that file associations changed.
    if (-not ('MdvInstaller.Shell' -as [type])) {
        Add-Type -Namespace MdvInstaller -Name Shell -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);'
    }
    [MdvInstaller.Shell]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)

    # 5. Add the folder to the user PATH, keeping existing %VARIABLE% entries intact.
    $envKey  = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    $oldPath = $envKey.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
    $entries = @($oldPath -split ';' | Where-Object { $_ })
    if ($entries -notcontains $installDir) {
        Write-Host 'Adding mdv to your PATH...'
        $envKey.SetValue('Path', (($entries + $installDir) -join ';'), 'ExpandString')
        # Setting a temporary variable makes Windows announce the PATH change to new windows.
        [Environment]::SetEnvironmentVariable('MDV_INSTALL_TMP', '1', 'User')
        [Environment]::SetEnvironmentVariable('MDV_INSTALL_TMP', $null, 'User')
        $env:Path = "$env:Path;$installDir"
    }
    $envKey.Close()

    Write-Host ''
    Write-Host 'mdv is installed.' -ForegroundColor Green

    # 6. Write a test page. The logo sits next to it, so the page also shows that relative images work.
    $welcome = Join-Path $installDir 'welcome.md'
    $welcomeLines = @()
    if ($logoPath) {
        $welcomeLines += '<p align="center"><img src="logo.png" width="128" alt="mdv logo"></p>', ''
    }
    $welcomeText = $welcomeLines + @(
        '# mdv is ready',
        '',
        'You are reading this file in mdv. Double-click any Markdown file to open it the same way.',
        '',
        'To open a file from a terminal, run `mdv file.md` in a new window.'
    ) -join "`r`n"
    [IO.File]::WriteAllText($welcome, $welcomeText, (New-Object Text.UTF8Encoding $false))

    # 7. Let the user make mdv the default app. Windows does not allow installers to do this.
    $choice = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.md\UserChoice' -ErrorAction SilentlyContinue
    if ($choice -and @($progId, 'Applications\mdv.bat') -contains $choice.ProgId) {
        Write-Host 'mdv is already your default app for .md files. Opening a test page...'
    } else {
        Write-Host ''
        Write-Host 'Last step: make mdv your default app for Markdown files.' -ForegroundColor Cyan
        Write-Host 'Windows Settings opens on the page for mdv. Click .md, select mdv and click Set default.'
        Write-Host 'If the page does not show mdv, go to Settings > Apps > Default apps, search for .md and choose mdv.'
        Start-Process 'ms-settings:defaultapps?registeredAppUser=mdv'
        Write-Host ''
        Read-Host 'When you are done, press Enter to open a test page' | Out-Null
    }
    Write-Host 'If the test page opens in your browser, everything works. If it opens in another app, mdv is not the default yet.'
    Start-Process -FilePath $welcome
}

try {
    Install-Mdv
} catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
}
