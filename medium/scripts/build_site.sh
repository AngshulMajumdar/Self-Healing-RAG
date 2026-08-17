#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
pandoc article.md -f gfm -t html5 --wrap=none > .article_body.html
python - <<'PY'
from pathlib import Path
root=Path('.')
body=(root/'.article_body.html').read_text()
html=f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Self-Healing RAG Is a Protocol, Not a Model</title>
  <meta name="author" content="Angshul Majumdar">
  <meta name="description" content="A technical explanation of Self-Healing RAG as a transaction protocol over retrieval state: residuals, repair, commit/rollback, cycle detection and bounded termination, with a worked local implementation.">
  <meta property="og:type" content="article">
  <meta property="og:title" content="Self-Healing RAG Is a Protocol, Not a Model">
  <meta property="og:description" content="Treat retrieval failure as observable state. Repair it with transactions. Commit only verified improvement. Roll back everything else.">
  <meta property="og:image" content="assets/figures/fig16_hero.png">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
<main>
<article>
{body}
<footer>
  <p>Article source, TikZ figure sources and compiled Medium-compatible figures are included in this GitHub Pages package.</p>
</footer>
</article>
</main>
</body>
</html>
'''
(root/'index.html').write_text(html)
(root/'.article_body.html').unlink()
PY
