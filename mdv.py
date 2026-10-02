#!/usr/bin/env python3
"""mdv - render a Markdown file as a styled HTML page and open it in the browser.

Usage:
    mdv.py path/to/file.md
"""

import hashlib
import html
import re
import sys
import tempfile
import webbrowser
from pathlib import Path
from urllib.parse import unquote, urlsplit

try:
    import markdown
except ImportError:
    sys.exit(
        "The 'markdown' package is not installed.\n"
        "Install the requirements with:  python -m pip install -r requirements.txt"
    )

try:
    from pygments.formatters import HtmlFormatter
    from pygments.util import ClassNotFound
except ImportError:  # Syntax highlighting is optional
    HtmlFormatter = None

EXTENSIONS = ["fenced_code", "codehilite", "tables", "toc", "sane_lists"]
EXTENSION_CONFIGS = {"codehilite": {"guess_lang": False}}

CSS = """
body{font-family:'Segoe UI',sans-serif;background:#1a1a2e;color:#e0e0e0;line-height:1.7;padding:2rem;max-width:900px;margin:0 auto}
h1{color:#4fc3f7;border-bottom:2px solid #4fc3f7;padding-bottom:.4rem;margin:2rem 0 1rem}
h2{color:#81c784;border-bottom:1px solid #333;padding-bottom:.3rem;margin:1.8rem 0 .8rem}
h3{color:#ffb74d;margin:1.5rem 0 .6rem}
h4{color:#ce93d8}
p{margin:.8rem 0}
a{color:#64b5f6}
strong{color:#fff}
img{max-width:100%}
code{background:#0d1117;padding:.15rem .4rem;border-radius:4px;font-family:Consolas,monospace;color:#e6db74}
pre{background:#0d1117;border:1px solid #333;border-radius:8px;padding:1rem;overflow-x:auto;margin:1rem 0}
pre code{background:none;padding:0;color:#e0e0e0}
blockquote{background:#16213e;border-left:4px solid #4fc3f7;padding:.8rem 1.2rem;margin:1rem 0;border-radius:0 8px 8px 0}
ul,ol{margin:.8rem 0;padding-left:1.8rem}
li{margin:.3rem 0}
table{border-collapse:collapse;width:100%;margin:1rem 0}
th{background:#16213e;color:#4fc3f7;padding:.6rem 1rem;border:1px solid #333}
td{padding:.5rem 1rem;border:1px solid #333}
tr:nth-child(even){background:rgba(255,255,255,.03)}
hr{border:none;border-top:1px solid #333;margin:2rem 0}
.hb{background:linear-gradient(135deg,#16213e,#1a1a2e);border:1px solid #333;border-radius:10px;padding:1rem 1.5rem;margin-bottom:2rem;display:flex;justify-content:space-between;gap:1rem}
.hb .fn{color:#4fc3f7;font-weight:600;word-break:break-all}
.hb .lb{color:#888;font-size:.85rem;white-space:nowrap}
"""

PAGE = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>{css}</style>
</head>
<body>
<div class="hb"><span class="fn">{title}</span><span class="lb">Markdown Preview</span></div>
{body}
</body>
</html>
"""

URL_ATTR = re.compile(r'\b(src|href)="([^"]*)"')


def highlight_css():
    """Return Pygments CSS for code blocks, or an empty string if unavailable."""
    if HtmlFormatter is None:
        return ""
    for style in ("github-dark", "monokai"):
        try:
            defs = HtmlFormatter(style=style).get_style_defs(".codehilite")
            # Let the page's own <pre> styling provide the background.
            return defs + "\n.codehilite{background:none}"
        except ClassNotFound:
            continue
    return ""


def absolutize_urls(body, base_dir):
    """Point relative links and images at the original file's folder.

    The preview is written to the temp folder, so a relative path like
    `images/diagram.png` would otherwise break. Absolute URLs, page anchors
    (#section) and other schemes (mailto:, https:) are left untouched.
    """

    def fix(match):
        attr, raw = match.group(1), html.unescape(match.group(2))
        parts = urlsplit(raw)
        if not raw or raw.startswith(("#", "/", "\\")) or parts.scheme or parts.netloc:
            return match.group(0)
        target = (base_dir / unquote(parts.path)).resolve()
        url = target.as_uri()
        if parts.query:
            url += "?" + parts.query
        if parts.fragment:
            url += "#" + parts.fragment
        return '{}="{}"'.format(attr, html.escape(url, quote=True))

    return URL_ATTR.sub(fix, body)


def output_path(source):
    """One preview file per source file, so several previews can be open at once."""
    digest = hashlib.sha1(str(source).encode("utf-8")).hexdigest()[:8]
    folder = Path(tempfile.gettempdir()) / "mdv"
    folder.mkdir(exist_ok=True)
    return folder / "{}-{}.html".format(source.stem, digest)


def render(source):
    text = source.read_text(encoding="utf-8-sig")  # utf-8-sig also handles a BOM
    body = markdown.markdown(
        text, extensions=EXTENSIONS, extension_configs=EXTENSION_CONFIGS
    )
    body = absolutize_urls(body, source.parent)
    return PAGE.format(
        title=html.escape(source.name), css=CSS + highlight_css(), body=body
    )


def main(argv):
    if len(argv) != 2:
        sys.exit("Usage: mdv <file.md>")

    source = Path(argv[1]).expanduser().resolve()
    if not source.is_file():
        sys.exit("File not found: {}".format(source))

    target = output_path(source)
    target.write_text(render(source), encoding="utf-8")
    webbrowser.open(target.as_uri())


if __name__ == "__main__":
    main(sys.argv)
