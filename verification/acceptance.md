# Chronicle migration acceptance checks

These checks were fixed from the change specification and the four LaTeX publication inputs before any Typst publication implementation was created.

## Build

- The documented command uses the pinned Typst release, exits zero, and creates non-empty `out/predvalecna_kronika_v2_0_0.pdf` and `out/soucasna_kronika_v2_0_0.pdf`.
- Invalid markup or any unavailable referenced source or asset makes the command exit non-zero and identify the failed edition.

## Content

- Each edition's heading sequence equals its `latex-baseline/*-sections.txt` inventory. The pre-war sequence reaches `Rok 1934 --- 40leté jubileum trvání` and `Pořad slavnostní valné hromady`; the contemporary sequence retains its introduction, historical overview, family chronicle, and contemporary chronicle sections.
- Normalized extraction of authored text preserves words, punctuation, emphasis, symbols, and order against `latex-baseline/*-text.txt`. Only `LaTeX` in each typesetting credit changes to `Typst`; surrounding wording stays unchanged.
- Every item in `latex-baseline/*-assets.txt` remains associated with the same edition and section. Contemporary source-PDF pages 1 through 36 and all four May 2025 photographs remain in source order.
- Every source construct in `latex-baseline/*-structured-blocks.txt` is reviewed against source and rendering. Lists retain nesting and labels; table cells retain row and column associations; quotations remain quotations; verse and explicit line breaks retain lineation; callouts and symbols remain distinct.

## PDF behavior

- Both PDFs declare Czech document and text language and render Czech glyphs, hyphenation, quotation behavior, and localized generated labels correctly.
- Both PDFs have visible contents, bookmark trees, working contents links, retained external URLs, consistent heading hierarchy, and page numbers plus running context on ordinary content pages.
- Images and full-page scan pages use contain sizing: entire media visible, useful size, unchanged aspect ratio, no unintended clipping.
- Review every page category listed in `latex-baseline/review-pages.md`; pagination differences alone do not fail acceptance.

## Maintainability

- Ordinary prose is native Typst markup in clearly named edition content files. No pre-war year section crosses a file boundary.
- Shared page, heading, contents, link, image, and callout rules live in one shared module; edition entry points only assemble their content and metadata.
- Contributor documentation states pinned Typst version, source layout, build command, output names, shared helpers, content conventions, and procedures for adding text, images, or scan pages.
