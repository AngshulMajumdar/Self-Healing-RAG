#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIKZ="$ROOT/tikz"
OUT="$ROOT/assets/figures"
BUILD="$ROOT/.figure-build"
mkdir -p "$OUT" "$BUILD"
rm -f "$BUILD"/*
for src in "$TIKZ"/fig*.tex; do
  base="$(basename "$src" .tex)"
  (cd "$TIKZ" && pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$BUILD" "$(basename "$src")" >/dev/null)
  pdftoppm -png -r 220 -singlefile "$BUILD/$base.pdf" "$OUT/$base" >/dev/null 2>&1
  echo "built $base.png"
done
