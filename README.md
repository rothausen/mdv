# mdv

Double-click a Markdown file and read it as a clean, styled page in your browser.

AI assistants, documentation and developer tools produce more and more `.md` files, and Notepad just shows the raw text. mdv turns any `.md` file into a readable page with one double-click. No editor, no browser extension, no server.

![mdv rendering this README](screenshot.png)

## Features

- Opens in your default browser with a dark, readable theme
- Tables, fenced code blocks with syntax highlighting and a table of contents (`[TOC]`)
- Relative images and links work, because they are resolved against the Markdown file's folder
- Each file gets its own preview, so you can have several open at once
- One small Python file with two dependencies

## Requirements

- Python 3.8 or newer
- The `markdown` and `pygments` packages. Pygments is optional: without it, code blocks are shown without colors.

## Installation on Windows

1. Put the files in a permanent folder, for example `C:\Users\<you>\bin\mdv`. Either download the repository as a ZIP from GitHub and unpack it there, or clone it:

   ```powershell
   git clone https://github.com/rothausen/mdv.git $HOME\bin\mdv
   ```

2. Install the dependencies:

   ```powershell
   py -m pip install -r $HOME\bin\mdv\requirements.txt
   ```

3. Make mdv the default app for `.md` files:
   1. Right-click any `.md` file and choose **Open with** → **Choose another app**.
   2. Click **Choose an app on your PC** and select `mdv.bat` in the folder from step 1.
   3. Click **Always**.

Double-clicking a `.md` file now opens it in your browser.

### Command line

Add the folder to your `PATH` to run mdv from any terminal:

```powershell
mdv README.md
```

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

MIT. See [LICENSE](LICENSE).
