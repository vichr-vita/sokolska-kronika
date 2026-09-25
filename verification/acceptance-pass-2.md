# Acceptance pass 2: tasks 6.3 and 6.4

Verified 2026-09-04 with Typst 0.15.1. Disposable 110 DPI renders were inspected from `/tmp/opencode/sokolska-pass-2`; no render was added to the repository.

## Visual review

- Pre-war chronicle: title 1, contents 2, credit and Czech prose 10, image 11, numbered list 15, table 25, callout 49-50, quotation 69, verse 79, image 80, nested quotation and verse 86, final page 108.
- Contemporary chronicle: title 1, contents 2, introductory scan 6, credit and Czech prose 7, historical prose 8, family transition 12, family scan 13, contemporary transition 20, contemporary scan 21, source scan 46, photographs 47-50, final page 50.
- Compared with the old LaTeX contact sheets and page list in `latex-baseline/review-pages.md`. Czech glyphs and discretionary hyphens render cleanly. Czech quotes include `„průvodce“` and `„Nazdar!“`. Generated labels read `Obsah` and `Novinový výstřižek`.
- Ordinary pages have readable spacing, stable heading levels, running headings, and centered page numbers. Full-page media has no running furniture. Images and scans remain uncropped at useful size and keep source proportions.
- The first `Výběr z rodinné kroniky Bártů` heading had been stranded at the foot of prose page 11. A weak page break now gives it a stable transition page at 12, matching the treatment of `Současná kronika` at page 20.
- Both PDFs are A4, tagged, and pass `qpdf --check`. Catalog `/Lang` and XMP `dc:language` are `cs`. Contents links, bookmark order, external links, scan signatures, photo dimensions, headers, page numbers, and final pages pass the tracked verification scripts.

## Credit proof

- Both source credits and rendered credit pages now name `Typst`; no Typst source credit contains `LaTeX`.
- The verifiers normalize each old LaTeX author statement, replace its single `LaTeX` token with `Typst`, and require exact equality with the current statement.
- Pre-war expected/current SHA-256: `b6f4859f65435e78d2c3ffb8f6967c1fafdfcb11a8b02143c07c58bacf80e826`.
- Contemporary expected/current SHA-256: `e2b7b4ee2e9bdeb376a397a36b6346e9ec3108b3f73a06b7ac70fd2a203f6a94`.
- `creditSystemOnlyChange` and `onlySystemNameChanged` are true in the tracked reports. Surrounding author text, emphasis, links, and intentional line break checks pass.

## Commands

- `./build.sh`
- `ruby verification/typst-prewar/verify_periods.rb`
- `ruby verification/typst-prewar/verify_structure.rb`
- `ruby verification/typst-prewar/verify_pdf.rb out/predvalecna_kronika_v2_0_0.pdf`
- `ruby verification/typst-contemporary/verify.rb out/soucasna_kronika_v2_0_0.pdf`
- `qpdf --check` on both outputs

All checks passed. The pre-war output is 108 pages and 13,052,323 bytes. The contemporary output is 50 pages and 86,671,457 bytes.
