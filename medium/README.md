# Self-Healing RAG — GitHub Pages / Medium article

This repository is deliberately minimal.

- `index.html` — complete publishable article; GitHub Pages serves this directly.
- `figures/` — 20 pre-rendered PNG figures used by the page and safe for Medium import.
- `tikz/` — the TikZ source for every figure plus one shared preamble.
- `.nojekyll` — tells GitHub Pages to serve the static files as-is.

## Publish on GitHub Pages

Upload the **contents** of this repository to the repository root. In **Settings → Pages**, choose **Deploy from a branch**, `main`, `/(root)`. No Jekyll theme, build workflow, JavaScript, npm, or other directory is required.

## Import into Medium

After GitHub Pages is live, use Medium's **Import a story** feature and give it the public GitHub Pages URL. The article does not rely on MathJax or JavaScript. All technical diagrams and equations that need layout fidelity are already rasterized from TikZ.

## Figure source

The PNGs were rendered from the `.tex` files in `tikz/` using `pdflatex` and `pdftoppm`. They are included pre-rendered so neither GitHub Pages nor Medium needs a TeX toolchain.
