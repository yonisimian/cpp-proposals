#!/usr/bin/env bash
# Render P3817.md to HTML.
# Fenced code blocks inside raw HTML table cells are converted to <pre><code>
# before passing to pandoc, so they get syntax highlighting like the rest.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: render.sh [OUTPUT]

Render P3817.md to a self-contained HTML file.

Arguments:
  OUTPUT   Path for the generated HTML (default: /tmp/P3817.html)

Options:
  -h, --help   Show this message and exit

Requirements:
  pandoc   Must be on PATH (tested with 3.9.0.2; other versions may differ in HTML structure)
  python3  Used to pre-process fenced code blocks inside raw HTML tables

Example:
  ./render.sh                        # writes to /tmp/P3817.html
  ./render.sh ~/Desktop/P3817.html   # writes to a custom path
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$SCRIPT_DIR/P3817.md"
OUTPUT="${1:-/tmp/P3817.html}"

CSS=$(cat <<'EOF'
<style>
  body          { max-width: none !important; }
  div.sourceCode{ overflow: visible !important; }
  pre           { white-space: pre-wrap; word-break: break-word; }
  header#title-block-header { display: none; }
  nav#TOC       { background: #f9f9f9; border: 1px solid #ddd; padding: 0.6em 1.2em; margin: 1.5em 0; display: inline-block; min-width: 20em; }
  nav#TOC h2    { margin-top: 0; font-size: 1em; border-bottom: 1px solid #ddd; padding-bottom: 0.3em; }
  table         { width: 100%; border-collapse: collapse; }
  td, th                              { vertical-align: top; padding: 0.4em 0.6em; }
  td > table, th > table              { margin: 0 auto; width: auto; }
  td > table th                       { vertical-align: middle; }
  #semantics-grid td,
  #semantics-grid th                  { border: 1px solid #aaa; }
  #semantics-grid td > table td,
  #semantics-grid td > table th       { border: 1px solid #aaa; }
  #semantics-grid > tbody > tr > th:first-child { vertical-align: middle; }
  #semantics-grid > tbody > tr > td             { vertical-align: middle; }
  #semantics-grid > tbody > tr > th:nth-child(2),
  #semantics-grid > tbody > tr > td:nth-child(2) { background-color: #f5fff5; }
  #semantics-grid > tbody > tr > th:nth-child(3),
  #semantics-grid > tbody > tr > td:nth-child(3) { background-color: #f5f5ff; }
  #semantics-grid > tbody > tr > th:nth-child(4),
  #semantics-grid > tbody > tr > td:nth-child(4) { background-color: #fff8f0; }
  #cpp26-table td, #cpp26-table th               { border: 1px solid #aaa; }
  :not(pre) > code                               { background-color: #f0f0f0; padding: 0.1em 0.3em; border-radius: 3px; }
  #semantics-summary td, #semantics-summary th   { border: 1px solid #aaa; vertical-align: middle; }
  #semantics-summary td:first-child              { width: 18em; }
  pre.sourceCode.diff .va { display: block; background-color: #e6ffe6; color: #006600; }
  pre.sourceCode.diff .st { display: block; background-color: #ffe6e6; color: #cc0000; }
</style>
EOF
)

PREPROC=$(python3 - "$INPUT" <<'PYEOF'
import re, sys, subprocess

import shutil
PANDOC = shutil.which('pandoc') or 'pandoc'
md = open(sys.argv[1]).read()

def highlight(lang, code):
    fence = f'```{lang}\n{code}\n```' if lang else f'```\n{code}\n```'
    r = subprocess.run(
        [PANDOC, '--syntax-highlighting=tango', '-f', 'markdown', '-t', 'html'],
        input=fence, capture_output=True, text=True)
    return r.stdout.strip()

def convert_fence(m):
    return highlight(m.group(1), m.group(2))

def convert_html_block(m):
    return re.sub(r'```(\w*)\n(.*?)```', convert_fence, m.group(0), flags=re.DOTALL)

print(re.sub(r'<table[\s\S]*?</table>', convert_html_block, md))
PYEOF
)

echo "$CSS" > /tmp/_p3817_css.html

echo "$PREPROC" | pandoc - \
  -s \
  --syntax-highlighting=tango \
  --metadata title="P3817R0 — Structured Binding Assignments" \
  --toc \
  -H /tmp/_p3817_css.html \
  -o "$OUTPUT"

# Post-process: move TOC to after the paper metadata block and add a "Contents" heading.
python3 - "$OUTPUT" <<'PYEOF'
import re, sys

html = open(sys.argv[1]).read()

# Extract the TOC nav element
toc_m = re.search(r'<nav id="TOC"[\s\S]*?</nav>', html)
if toc_m:
    toc = toc_m.group(0)
    # Add "Contents" heading inside the nav if not already present
    if '<h2' not in toc:
        toc = re.sub(r'(<nav[^>]*>)', r'\1\n<h2>Contents</h2>', toc, count=1)
    # Strip the top-level TOC entry (the h1 document title) so the list
    # starts directly with the ## sections.
    h2_end  = toc.find('</h2>') + len('</h2>')
    nav_close = toc.rfind('</nav>')
    outer_ul_open  = toc.find('<ul>', h2_end)
    outer_ul_close = toc.rfind('</ul>', 0, nav_close)
    outer_ul_close_end = outer_ul_close + len('</ul>')
    inner_ul_open  = toc.find('<ul>', outer_ul_open + len('<ul>'))
    outer_li_close = toc.rfind('</li>', 0, outer_ul_close)
    if inner_ul_open != -1 and outer_li_close != -1:
        toc = toc[:outer_ul_open] + toc[inner_ul_open:outer_li_close] + toc[outer_ul_close_end:]
    # Remove TOC from its current position
    html = html[:toc_m.start()] + html[toc_m.end():]
    # Insert after the paper metadata: last </ul> before the first <h2>
    h1_end = html.find('</h1>') + len('</h1>')
    h2_idx = html.find('<h2 ', h1_end)
    ul_end = html.rfind('</ul>', h1_end, h2_idx)
    if ul_end != -1:
        pos = ul_end + len('</ul>')
        html = html[:pos] + '\n' + toc + html[pos:]

open(sys.argv[1], 'w').write(html)
PYEOF

echo "Rendered: $OUTPUT"
