# Self-Healing RAG — GitHub Pages / Medium article package

This ZIP is a complete, self-contained publication package for the long-form article:

**Self-Healing RAG Is a Protocol, Not a Model**

The page is intentionally framed around the protocol. The financial-document QA system is presented as a worked reference implementation, not as the definition of the contribution.

## What is included

- `index.html` — directly publishable GitHub Pages page.
- `article.md` — editable long-form source (~4.3k words).
- `assets/css/style.css` — responsive GitHub Pages styling.
- `assets/figures/` — pre-rendered high-resolution PNG figures for GitHub Pages and Medium import.
- `tikz/` — all figure sources in TikZ/PGFPlots.
- `scripts/build_figures.sh` — recompiles every TikZ figure and rasterizes it to a Medium-safe PNG.
- `scripts/build_site.sh` — rebuilds `index.html` from `article.md` using Pandoc.
- `scripts/check_site.py` — verifies local image/style references, alt text, and the TikZ/PNG figure count.
- `.nojekyll` — prevents GitHub Pages/Jekyll from altering the static package.

There are 16 TikZ-generated graphics in the package, including the hero image. The explanatory figures cover the state machine, transaction lifecycle, residual, protected-support commit rule, cycle termination, data lineage, retrieval bottleneck, measured residual descent, rollback counts, validation routing, runtime, v0.2 compression, and the protocol/implementation boundary.

## Publish directly as a GitHub Pages site

The ZIP root is already the site root. The cleanest deployment is a `gh-pages` branch containing the files exactly as provided, then select that branch and `/ (root)` in GitHub **Settings → Pages**.

## Drop it into the existing Self-Healing-RAG repository

If you want to keep the existing repository as the canonical home, copy the contents of this package into:

`docs/medium/`

Then configure GitHub Pages to publish `main` from `/docs`. The article will then be reachable under the repository Pages URL with `/medium/` appended.

Do not copy the package over the existing technical `docs/` files; place it in the `docs/medium/` subdirectory so the POC PDF and other repository documentation remain untouched.

## Import into Medium

After the GitHub Pages URL is live, use Medium's **Import a story** function and paste the published page URL. The article does not depend on MathJax, KaTeX, JavaScript, SVG rendering, or a web font. All critical diagrams are already PNG files produced from TikZ, which is deliberate: Medium only needs to fetch normal page text and images.

The equations that matter for the argument are also written in ordinary article text/code form, so the imported story remains intelligible even when Medium strips the site's CSS.

## Rebuild the figures

Requirements: a TeX installation with TikZ/PGFPlots, `pdflatex`, and Poppler's `pdftoppm`.

```bash
./scripts/build_figures.sh
```

The script compiles each `tikz/fig*.tex` source and writes the PNG into `assets/figures/` at 220 dpi.

## Rebuild the HTML

Requires Pandoc:

```bash
./scripts/build_site.sh
```

## Validate before publishing

```bash
python scripts/check_site.py
```

The publication-facing images were manually inspected after compilation. During that pass, label collisions in the controller diagrams, legend/caption collisions in the charts, overplotted transaction bars, a clipped residual label, and the hero-title/subtitle collision were corrected before packaging.

## Project links used by the article

- Protocol / v0.1: https://github.com/AngshulMajumdar/Self-Healing-RAG
- Compact v0.2 implementation: https://github.com/AngshulMajumdar/Self-Healing-RAG-V2
