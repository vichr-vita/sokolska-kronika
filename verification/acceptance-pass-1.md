# Acceptance pass 1: tasks 6.1 and 6.2

Verified 2026-09-04 with Typst 0.15.1.

## Build proof

- `rm -rf -- out && ./build.sh` exited zero and created non-empty `out/predvalecna_kronika_v2_0_0.pdf` (13,052,348 bytes) and `out/soucasna_kronika_v2_0_0.pdf` (86,670,661 bytes).
- With referenced source `chronicles/soucasna/content/historical-overview.typ` moved behind an exit trap, `./build.sh` exited 1, reported `file not found`, and identified `Současná kronika` plus `chronicles/soucasna/main.typ` as the failed compilation. The trap restored the source; a final clean build passed.

## Content proof

- `ruby verification/typst-prewar/verify_periods.rb` passed all 200 stable section titles, front matter, links, ordered media, normalized authored text, and intentional front-matter line breaks.
- `ruby verification/typst-prewar/verify_structure.rb` matched all eight period files byte-for-byte to source-derived Typst, matched all 705 stable structured inventory records, and passed structure order/counts, 846 list items, three tables, quotation nesting, four verse lineations, 110 intentional breaks, and symbol sequence checks.
- `ruby verification/typst-prewar/verify_pdf.rb out/predvalecna_kronika_v2_0_0.pdf` passed PDF integrity, outline order, links, metadata, and final-page checks.
- `ruby verification/typst-contemporary/verify.rb out/soucasna_kronika_v2_0_0.pdf` passed all 12 stable section titles, authored text, emphasis, links, structured inventory, scan ranges 1-36, direct scan-page signatures, and four ordered photographs.

Generated details are tracked in `typst-prewar/period-comparison.json`, `typst-prewar/structured-comparison.json`, `typst-prewar/pdf-verification.json`, and `typst-contemporary/verification.json`.
