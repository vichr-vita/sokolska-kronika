# TJ Sokol Poruba chronicles

[![PDF publication](https://github.com/vichr-vita/sokolska-kronika/actions/workflows/publish-pdfs.yml/badge.svg?branch=master)](https://github.com/vichr-vita/sokolska-kronika/actions/workflows/publish-pdfs.yml)
[![Latest PDF release](https://img.shields.io/github/v/release/vichr-vita/sokolska-kronika?label=PDF%20release)](https://github.com/vichr-vita/sokolska-kronika/releases/latest)

This repository contains the source text and media for two digital chronicles of TJ Sokol Poruba:

- the pre-war chronicle, from the founding of the club through 1934;
- the contemporary chronicle, which combines typeset text, pages from a source PDF, and photographs.

Both editions use the same Typst layout and build as separate PDF files.

## Requirements

The project is tested with the [Typst 0.15.1](https://github.com/typst/typst/releases/tag/v0.15.1) CLI. Install that version using the [official instructions](https://github.com/typst/typst#installation) and make sure `typst` is on your `PATH`.

Check the version with:

```sh
typst --version
```

The output must start with `typst 0.15.1`.

## Build

Run this from the repository root:

```sh
./build.sh
```

The script moves to the repository root, removes any stale output files, and builds both editions with `--root .`. If Typst is missing or compilation fails, it exits with a non-zero status and identifies the failed edition.

A successful build creates:

```text
out/predvalecna_kronika_v3_0_0.pdf
out/soucasna_kronika_v3_0_0.pdf
```

Version 3 marks the editions typeset with Typst instead of LaTeX.

## PDF publication

Submit changes through pull requests targeting `dev`. Merging `dev` into `master` runs the `Publish PDFs` workflow. The workflow builds and checks both chronicles, then publishes them as a new GitHub Release. Any other push to `master` also runs it.

Set the WordPress links to the latest release once:

```text
https://github.com/vichr-vita/sokolska-kronika/releases/latest/download/predvalecna_kronika.pdf
https://github.com/vichr-vita/sokolska-kronika/releases/latest/download/soucasna_kronika.pdf
```

Release asset names stay the same when the version number in `build.sh` changes. These links will work after the first successful workflow run on `master`.

To compile one edition during development, run this from the repository root:

```sh
typst compile --root . chronicles/predvalecna/main.typ /tmp/predvalecna.pdf
typst compile --root . chronicles/soucasna/main.typ /tmp/soucasna.pdf
```

## Source layout

```text
chronicles/
  shared/publication.typ          shared layout and media helpers
  predvalecna/
    main.typ                      pre-war edition assembly
    content/front-matter.typ      title and introductory pages
    content/1894-1900.typ         complete year sections grouped by period
    content/...
  soucasna/
    main.typ                      contemporary edition assembly
    content/front-matter.typ      title, contents, introduction, and author's note
    content/historical-overview.typ
    content/scans.typ             PDF page ranges and photographs
images/                           image assets
scans/                            source scans, PDFs, and photographs
verification/                     verification scripts and recorded results
out/                              built PDFs, ignored by Git
```

Each `main.typ` sets edition metadata and assembles content in its final order. Put ordinary prose in named files under the edition's `content/` directory. Put shared layout rules in `chronicles/shared/publication.typ`.

## Shared helpers

The `chronicles/shared/publication.typ` module provides:

- `publication`: Czech document metadata and text language, A4 page size, margins, font, headings, links, running headers, and page numbers;
- `publication-outline()`: localized table of contents with internal links;
- `title-page(...)`: a title page with an optional image, edition label, and date;
- `full-page-image(source, page-number: none)`: one image or one PDF page on a full output page;
- `pdf-page-range(source, start, end)`: every page in the inclusive, one-based range from `start` to `end`;
- `image-sequence(sources)`: a sequence of separate full-page images;
- `newspaper-clipping(body)`: a framed newspaper clipping;
- `verse(body)`: verse with preserved line breaks.

The full-page helpers use `fit: "contain"`. They show the entire image or page, preserve its aspect ratio, and do not crop it.

## Editing text

Write ordinary content in native Typst markup. Use `=`, `==`, and `===` for the existing heading levels, `_italics_`, `*bold text*`, `#quote[...]` for quotations, and `#link("https://...")[text]` for links. Put a backslash at the end of a line for an intentional line break.

Preserve the original wording, punctuation, meaningful spacing, emphasis, order, lists, captions, table relationships, nested quotations, verse, and symbols. Do not modernize or edit the style of historical text without a separately approved correction. In the pre-war edition, do not split a year's content across period files.

After adding or renaming a heading, check its order in the table of contents and PDF bookmarks. Use a real `link` element for a URL, rather than displaying the address as plain text.

## Images and scans

Media paths start with a slash and are relative to the root passed with `--root .`, such as `/images/cover.jpg` or `/scans/nova_kronika_scans.pdf`. Put new assets in a suitable subdirectory of `images/` or `scans/`, not among the sources in `chronicles/`.

Use `full-page-image` for a single full-page image and `image-sequence` for several images in a set order. Preserve their aspect ratios, do not crop them, and do not replace a source with a raster copy just for typesetting.

Include source PDF pages directly:

```typ
#pdf-page-range("/scans/nova_kronika_scans.pdf", 4, 10)
```

Page numbers are one-based, and the range includes both endpoints. Use separate calls for consecutive ranges beside their sections so the boundaries and order stay clear. Do not rasterize the PDF before including it.

## Checks

After a change, build both editions with `./build.sh`. Run the focused PDF checks with:

```sh
ruby verification/typst-prewar/verify_pdf.rb out/predvalecna_kronika_v3_0_0.pdf
ruby verification/typst-contemporary/verify.rb out/soucasna_kronika_v3_0_0.pdf
```

The contemporary edition checks also cover text, headings, a link, emphasis, scan ranges, and the order of inserted pages. Before submitting changes, visually inspect the changed text pages, full-page media boundaries, and final page.
