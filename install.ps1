# install.ps1 - Install mdv (Markdown viewer) for the current Windows user.
#
# Run from PowerShell:
#   irm https://raw.githubusercontent.com/rothausen/mdv/main/install.ps1 | iex
#
# What it does:
#   1. Downloads mdv.py and mdv.bat to %USERPROFILE%\bin\mdv
#   2. Installs the Python packages mdv needs (markdown, pygments)
#   3. Adds mdv to the "Open with" list for .md and .markdown files
#   4. Adds the folder to your user PATH so "mdv file.md" works in a terminal
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

    # 3. Install the Python packages.
    Write-Host 'Installing Python packages (markdown, pygments)...'
    & $python -m pip install --quiet --disable-pip-version-check --upgrade 'markdown>=3.3' 'pygments>=2.10'
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Package installation failed. See the pip output above.' -ForegroundColor Red
        return
    }

    # 4. Register mdv in the "Open with" list. Existing keys are reused, never wiped.
    Write-Host 'Adding mdv to the Open with list...'
    function Use-Key($path) {
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        $path
    }
    $appKey = 'HKCU:\Software\Classes\Applications\mdv.bat'
    Set-ItemProperty -Path (Use-Key "$appKey\shell\open\command") -Name '(default)' -Value "`"$batPath`" `"%1`""
    Set-ItemProperty -Path (Use-Key $appKey) -Name 'FriendlyAppName' -Value 'mdv'
    $typesKey = Use-Key "$appKey\SupportedTypes"
    foreach ($ext in $extensions) {
        Set-ItemProperty -Path $typesKey -Name $ext -Value ''
        Use-Key "HKCU:\Software\Classes\$ext\OpenWithList\mdv.bat" | Out-Null
    }

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
    Write-Host 'Last step: right-click any .md file, choose Open with > Choose another app, select mdv and click Always.'
}

try {
    Install-Mdv
} catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
}
