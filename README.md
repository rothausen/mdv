<p align="center">
  <img src="https://raw.githubusercontent.com/rothausen/mdv/main/logo.png" width="128" alt="mdv logo">
</p>

# mdv

Double-click a Markdown file and read it as a clean, styled page in your browser.

AI assistants, documentation and developer tools produce more and more `.md` files, and Notepad just shows the raw text. mdv turns any `.md` file into a readable page with one double-click. No editor, no browser extension, no server.

![mdv rendering this README](https://raw.githubusercontent.com/rothausen/mdv/main/screenshot.png)

## Features

- Opens in your default browser with a dark, readable theme
- Tables, fenced code blocks with syntax highlighting and a table of contents (`[TOC]`)
- Relative images and links work, because they are resolved against the Markdown file's folder
- Each file gets its own preview, so you can have several open at once
- One small Python file with two dependencies

## Install on Windows

You need [Python](https://www.python.org/downloads/) 3.8 or newer.

1. Download [install.cmd](https://github.com/rothausen/mdv/releases/latest/download/install.cmd) and double-click it.
2. At the end, Windows Settings opens on the page for mdv. Click **.md**, select **mdv** and click **Set default**.
3. Go back to the installer window and press **Enter**. A test page opens in your browser.

That's it. Windows does not let installers change the default app for a file type, so the last click is up to you.

The file is not signed, so your browser and Windows may warn about it. In Chrome, choose **Keep**. If Windows says it protected your PC, choose **More info** and then **Run anyway**.

Prefer the terminal? Run this in PowerShell instead:

```powershell
irm https://raw.githubusercontent.com/rothausen/mdv/main/install.ps1 | iex
```

The installer puts mdv in `%USERPROFILE%\bin\mdv`, installs the `markdown` and `pygments` packages, registers mdv as an app for `.md` and `.markdown` files with its own icon and adds the folder to your `PATH`, so `mdv file.md` also works in a new terminal. Everything is per-user and needs no administrator rights. You can read [install.cmd](https://github.com/rothausen/mdv/blob/main/install.cmd) and [install.ps1](https://github.com/rothausen/mdv/blob/main/install.ps1) before running them.

<details markdown="1">
<summary>Manual installation</summary>

Download the repository as a ZIP, unpack it to a permanent folder such as `C:\Users\<you>\bin\mdv`, and install the packages:

```powershell
py -m pip install -r requirements.txt
```

Then right-click any `.md` file, choose **Open with** → **Choose another app** → **Choose an app on your PC**, select `mdv.bat` and click **Always**. The manual installation does not register the icon.

</details>

<details markdown="1">
<summary>Uninstall</summary>

Delete the folder and the registry entries:

```powershell
Remove-Item -Recurse -ErrorAction SilentlyContinue "$HOME\bin\mdv", "HKCU:\Software\mdv", "HKCU:\Software\Classes\mdv.MarkdownFile", "HKCU:\Software\Classes\Applications\mdv.bat"
Remove-ItemProperty -ErrorAction SilentlyContinue "HKCU:\Software\Classes\.md\OpenWithProgids", "HKCU:\Software\Classes\.markdown\OpenWithProgids" -Name mdv.MarkdownFile
Remove-ItemProperty -ErrorAction SilentlyContinue "HKCU:\Software\RegisteredApplications" -Name mdv
```

Then pick another default app for `.md` files under **Settings** → **Apps** → **Default apps**.

Finally, remove `%USERPROFILE%\bin\mdv` from your `PATH`: search the Start menu for **Edit environment variables for your account**.

</details>

## macOS and Linux

```bash
python3 -m pip install -r requirements.txt
python3 mdv.py README.md
```

To use it as a command, add an alias to your shell profile:

```bash
alias mdv='python3 /path/to/mdv/mdv.py'
```

## How it works

mdv converts the Markdown to HTML with [Python-Markdown](https://python-markdown.github.io/), adds a built-in stylesheet and writes the page to an `mdv` folder in your system's temp directory. It then opens that page in your default browser. Your original file is never changed.

To see changes after editing a file, open it again.

## License

MIT. See [LICENSE](https://github.com/rothausen/mdv/blob/main/LICENSE).
