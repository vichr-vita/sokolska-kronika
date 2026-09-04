## Context

See `proposal.md` for motivation and `specs/chronicle-publication/spec.md` for required behavior.

The repository has two LaTeX entry points with nearly identical preambles. The pre-war prose occupies one 3,877-line file and covers introductory material plus yearly sections from 1894 through 1934. The contemporary edition combines authored text, pages from a 36-page source PDF, and four standalone photographs. Current generated PDFs report 140 and 53 pages, but the build runs LaTeX only once and can leave contents and references unresolved. The asset directories contain about 231 MB of images and scans, and the generated `out/` directory is ignored by Git.

Typst is not installed in the current development environment. Its standard `image` element supports JPEG, PNG, and PDF input, including selection of an individual PDF page. The source scan uses PDF 1.3 and is not encrypted, so Typst can embed it directly.

## Goals / Non-Goals

**Goals:**

- Keep ordinary content close to the plain text a contributor reads in the PDF.
- Give both editions one small, documented set of layout helpers.
- Preserve the existing build entry point and release filenames.
- Make conversion reviewable in sections rather than replacing all 4,273 LaTeX lines at once.

**Non-Goals:**

- Copy-edit, modernize, translate, or fact-check chronicle text.
- OCR the contemporary scanned pages or replace them with transcriptions.
- Match LaTeX line breaks or page numbers exactly.
- Redesign the chronicle's visual identity or relocate large binary assets.
- Add third-party Typst packages unless the standard library cannot meet a requirement.

## Decisions

### Use edition directories with one shared module

Typst sources will use this shape:

```text
chronicles/
  shared/
    publication.typ
  predvalecna/
    main.typ
    content/
      front-matter.typ
      <period>.typ
  soucasna/
    main.typ
    content/
      front-matter.typ
      historical-overview.typ
      scans.typ
```

`publication.typ` will expose one document setup function and only the helpers needed by both editions, such as a title page, full-page media, a range of PDF pages, and the newspaper clipping callout. It will own Czech language configuration, page geometry, typography, heading rules, the outline, running headers, page numbers, and link styling. Each `main.typ` will supply edition metadata and include content in order.

Pre-war period files will split at year boundaries and stay small enough to review comfortably. Exact ranges can follow natural historical periods and source size, but no year section will span files. The contemporary scan sequence will live in its own short assembly file rather than expand the entry point.

This layout separates prose from presentation without introducing a deep component hierarchy. Keeping everything in one file was rejected because it repeats the current maintenance problem. A module per visual element was rejected because the project has too few layout concepts to justify that many files.

### Keep `images/` and `scans/` at the repository root

Typst sources will reference the existing assets through a repository-root compilation. The build will pass `--root .`, which permits nested Typst entry points to read those directories.

Moving 231 MB of binary files would create noisy renames and break paths without improving content editing. Existing folders already group their material by subject. Asset cleanup can happen separately if a concrete naming or duplication problem appears.

### Prefer native Typst markup and the standard library

Content files will use native headings, paragraphs, emphasis, quotations, links, bullet lists, numbered lists, and term lists. Helpers will cover only repeated publication behavior or cases where raw Typst would obscure intent. Long paragraphs will remain prose rather than become function arguments.

The shared document setup will set `text.lang` to `"cs"` and select a font included with the supported Typst distribution. Verification will cover Czech glyphs, hyphenation, smart quotes, generated labels such as the contents title, and PDF language metadata. This avoids English defaults and machine-specific system font dependencies. No Typst Universe package is planned because standard page, outline, heading, figure, link, and image features cover the current documents.

A broad compatibility layer that mimics LaTeX commands was rejected. It would preserve the syntax and indirection this change is meant to remove.

### Embed scanned PDF pages directly

The shared module will render selected source-PDF pages with `image(path, page: number, fit: "contain")`, one source page per output page. A helper will accept `start` and `end` page numbers and iterate with `range(start, end, inclusive: true)`. The contemporary source can then request pages 1 through 3, 4 through 10, and 11 through 36 without repeating 36 image calls. Standalone image sequences will use the same contain-without-distortion rule.

Converting PDF pages to raster images was rejected because it duplicates source material, increases repository size, and may reduce quality.

### Keep `build.sh` as the public build command

`build.sh` will use strict shell error handling, create `out/`, and invoke `typst compile` for both entry points. It will compile directly to the existing versioned filenames. The script will fail before reporting success if Typst is missing or either edition fails.

The README will name the tested Typst version and explain installation separately from building. A larger task runner was rejected because two compile commands do not warrant another dependency.

### Validate content and presentation against the current release

Migration will keep the LaTeX sources and current PDFs available until both Typst editions pass review. Before recording the baseline, LaTeX will run from a clean output directory until contents and references stop changing. Validation will combine:

- successful clean builds of both entry points;
- section-title and asset-reference inventories before and after conversion;
- normalized text extraction comparisons for typeset text plus source and visual checks for tables, term lists, quotations, verse, intentional line breaks, and symbols;
- checks of output metadata, bookmarks, links, page count, and missing assets;
- visual review of title, contents, ordinary prose, lists, tables, quotations, verse, callouts, images, scan boundaries, headers, and final pages.

Exact page count is diagnostic rather than a pass condition because Typst will line-break and paginate prose differently. Content order, media completeness, navigation, and readability are pass conditions.

## Risks / Trade-offs

- [Manual conversion drops or changes historical text] -> Convert period by period, compare normalized extracted text, and review source diffs before removing LaTeX.
- [Text extraction hides damaged tables or verse] -> Inventory structured blocks and compare row associations, nesting, symbols, and lineation against source and rendered baseline.
- [Different line breaking creates poor page turns or stranded headings] -> Review rendered pages and apply local, documented page-break adjustments only where needed.
- [Headers, bookmarks, or outline entries differ around unnumbered headings and full-page media] -> Centralize heading behavior and test every top-level section link in both editions.
- [A supported Typst release changes typography] -> Document the tested version and compare generated PDFs when upgrading it.
- [Direct PDF embedding fails under a future PDF export standard] -> Keep the original source PDF; rasterize or convert it only if the project later adopts an incompatible PDF standard.
- [Period files become arbitrary fragments] -> Split only between complete year sections and use filenames that state their covered years.

## Migration Plan

1. From a clean output directory, run LaTeX repeatedly until contents and references stabilize, then record baseline section inventories, asset references, extracted text, structured blocks, and representative rendered pages.
2. Install the chosen Typst release and create the shared publication module plus minimal edition entry points.
3. Convert common front matter and verify title, contents, headers, links, typography, and full-page media behavior.
4. Convert the pre-war chronicle in complete period files, validating each period before continuing.
5. Convert contemporary authored text, direct PDF-page ranges, and the May 2025 image sequence.
6. Update `build.sh` and README, then run structural, text, link, bookmark, and visual checks on both PDFs.
7. Remove LaTeX sources only after acceptance, then run a clean Typst-only build.

Until step 7, rollback means using the untouched LaTeX sources and current build. After removal, Git history remains the rollback path; generated baseline PDFs stay available locally during review.
