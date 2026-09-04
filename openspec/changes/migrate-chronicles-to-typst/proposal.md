## Why

The chronicles are difficult to edit because their prose is mixed with repetitive LaTeX commands and layout configuration. Moving the publication workflow to Typst will shorten the markup, make the long historical text easier to read in source form, and give both editions one shared layout to maintain.

## What Changes

- Replace the LaTeX sources and `pdflatex` build with Typst sources and a Typst build.
- Keep producing the pre-war and contemporary chronicle as separate, navigable PDF files.
- Preserve Czech text, historical wording, images, scanned pages, section hierarchy, links, contents, page headers, and other meaningful presentation from the current editions.
- Split long content into clearly named files grouped by edition and subject or period.
- Move shared page, heading, contents, link, image, and callout styling into reusable Typst modules instead of duplicating it between editions.
- Document the source layout, prerequisites, build command, output files, and conventions for adding or editing content.
- Remove superseded LaTeX sources and LaTeX-specific build dependencies after the Typst output has been checked.

## Capabilities

### New Capabilities

- `chronicle-publication`: Build both chronicle editions from maintainable sources into readable, navigable PDFs.

### Modified Capabilities

None.

## Impact

- Replaces the four current `.tex` files and the LaTeX package stack with Typst source files and shared modules.
- Changes `build.sh` to require the Typst CLI while retaining the two versioned PDF deliverables under `out/`.
- Reorganizes chronicle source files while keeping the existing `images/` and `scans/` directories as source material.
- Updates contributor documentation and the wording inside each chronicle that currently identifies LaTeX as the typesetting system.
- The migration can cause pagination and line-break changes, so implementation requires visual and structural comparison against the current PDFs.
