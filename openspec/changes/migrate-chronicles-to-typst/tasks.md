## 1. Baseline and tooling

- [x] 1.1 Build both LaTeX editions from a clean output directory with repeated passes until contents and references stop changing, then record page counts, section titles, links, referenced assets, extracted text, structured blocks, and representative review pages.
- [x] 1.2 Select and install a tested Typst release, verify its Czech font and language support, and prove that it can embed a selected page from `scans/nova_kronika_scans.pdf` without raster conversion.

## 2. Shared Typst publication layer

- [x] 2.1 Create the `chronicles/shared`, `chronicles/predvalecna/content`, and `chronicles/soucasna/content` structure with minimal edition entry points.
- [x] 2.2 Implement `chronicles/shared/publication.typ` with explicit Czech text and document language, common page geometry, typography, heading hierarchy, localized outline, bookmarks, links, running headers, and page numbers.
- [x] 2.3 Add focused helpers for title pages, full-page images, inclusive PDF-page ranges using `range(start, end, inclusive: true)`, image sequences, and newspaper clipping callouts; verify that media uses contain sizing and keeps its aspect ratio.

## 3. Pre-war chronicle conversion

- [x] 3.1 Convert the pre-war title, introductory pages, historical postcards, author text, and pre-1894 sections into `front-matter.typ`, preserving text, links, captions, and images.
- [x] 3.2 Convert complete year sections 1894 through 1900 into a named period file and compare its headings and normalized extracted text with LaTeX.
- [x] 3.3 Convert complete year sections 1901 through 1905 into a named period file and compare its headings, media references, and normalized extracted text with LaTeX.
- [x] 3.4 Convert complete year sections 1906 through 1910 into a named period file and compare its headings, media references, and normalized extracted text with LaTeX.
- [x] 3.5 Convert complete year sections 1911 through 1915 into a named period file and compare its headings, media references, and normalized extracted text with LaTeX.
- [x] 3.6 Convert complete year sections 1916 through 1920 into a named period file and compare its headings, media references, and normalized extracted text with LaTeX.
- [x] 3.7 Convert complete year sections 1921 through 1925 into a named period file and compare its headings, media references, and normalized extracted text with LaTeX.
- [x] 3.8 Convert complete year sections 1926 through 1930 into a named period file and compare its headings, media references, and normalized extracted text with LaTeX.
- [x] 3.9 Convert complete year sections 1931 through 1934 into a named period file and compare its headings, media references, and normalized extracted text with LaTeX.
- [x] 3.10 Assemble all pre-war files in `chronicles/predvalecna/main.typ` and verify the full section order, contents links, bookmark tree, headers, and final page.

## 4. Contemporary chronicle conversion

- [x] 4.1 Convert the contemporary title, introductory pages, author text, and historical overview into native Typst content files, preserving wording, hierarchy, links, and emphasis.
- [x] 4.2 Implement the three source-PDF ranges for pages 1 through 36 and the four May 2025 photographs in `scans.typ`, preserving their order and section boundaries.
- [x] 4.3 Assemble all contemporary files in `chronicles/soucasna/main.typ` and verify the full section order, contents links, bookmark tree, headers, scan boundaries, and final image.

## 5. Build and contributor documentation

- [x] 5.1 Replace the LaTeX commands in `build.sh` with strict Typst compilation from repository root to the two existing versioned output filenames, including clear missing-tool and compilation failures.
- [x] 5.2 Rewrite `README.md` with the tested Typst version, installation prerequisite, project layout, build and output details, shared helper reference, and conventions for editing text or adding media.

## 6. Acceptance and cleanup

- [ ] 6.1 Run a clean build and verify both required PDFs exist, are non-empty, and cause the build to fail when a referenced asset or source is unavailable.
- [ ] 6.2 Compare every section title, authored text block, structured block, link target, image reference, and scan page against the stable LaTeX baseline; verify table associations, quotation nesting, verse lineation, intentional line breaks, and symbols, then resolve every unexplained omission, duplicate, or reordering.
- [ ] 6.3 Review both PDFs at title, contents, prose, list, table, quotation, verse, callout, image, scan, transition, and final pages for Czech glyphs, hyphenation, smart quotes, localized labels, language metadata, readable spacing, stable headings, useful media size, headers, and page numbers.
- [ ] 6.4 Update in-document typesetting credits from LaTeX to Typst without changing the surrounding author statement.
- [ ] 6.5 After both editions pass acceptance, remove the four superseded `.tex` files and LaTeX-specific instructions, then confirm a clean checkout builds using only documented Typst inputs.
