#!/usr/bin/env python3
"""Render docs/store/privacy-policy.md into a standalone HTML page.

Usage: build-privacy-page.py <input.md> <output.html>
"""
import sys

import markdown

TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Elyanotes - Privacy policy / Gizlilik politikasi</title>
<style>
  :root {{ color-scheme: light dark; }}
  body {{ font: 16px/1.6 system-ui, sans-serif; max-width: 42rem;
         margin: 0 auto; padding: 1rem 1rem 4rem; }}
  h1, h2, h3 {{ line-height: 1.25; }}
  a {{ color: #2a5bd7; }}
  @media (prefers-color-scheme: dark) {{ a {{ color: #8ab4ff; }} }}
  code {{ font-size: .9em; }}
</style>
</head>
<body>
{body}
</body>
</html>
"""


def main(src: str, dst: str) -> None:
    with open(src, encoding="utf-8") as f:
        text = f.read()
    body = markdown.markdown(text, extensions=["toc", "tables"])
    with open(dst, "w", encoding="utf-8") as f:
        f.write(TEMPLATE.format(body=body))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
