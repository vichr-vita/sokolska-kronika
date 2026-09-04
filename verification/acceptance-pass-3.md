# Acceptance pass 3: task 6.5

Verified 2026-09-04 with Typst 0.15.1.

## Acceptance before removal

- `./build.sh` created both required nonempty PDFs.
- `ruby verification/typst-prewar/verify_periods.rb`, `ruby verification/typst-prewar/verify_structure.rb`, `ruby verification/typst-prewar/verify_pdf.rb out/predvalecna_kronika_v2_0_0.pdf`, and `ruby verification/typst-contemporary/verify.rb out/soucasna_kronika_v2_0_0.pdf` passed while the frozen LaTeX sources were still present.
- `qpdf --check` passed for both outputs.
- These results confirm the evidence recorded for tasks 6.1 through 6.4 before source removal.

## Cleanup and current checks

- Removed `nova_kronika_main.tex`, `nova_kronika_historicky_prehled_klos.tex`, `stara_kronika_main.tex`, and `stara_kronika.tex`.
- Searches found no dependency on those files, `pdflatex`, or LaTeX in `build.sh`, root contributor documentation, or `chronicles/**/*.typ`.
- LaTeX references remain only in frozen baseline records, historical acceptance reports, and source-comparison utilities. They describe completed migration checks and are not build inputs or current contributor instructions.
- The current contemporary verifier now binds its source checks to the accepted Typst source hashes while retaining PDF, scan, image, link, outline, metadata, and layout checks.
- A post-removal `./build.sh`, both PDF verification commands documented in `README.md`, and `qpdf --check` passed.

## Tracked-only build

- The staged index was exported with `git checkout-index` to a temporary directory under `/tmp`.
- The export contained tracked files only and none of the four removed TeX paths.
- Running its `./build.sh` created nonempty `out/predvalecna_kronika_v2_0_0.pdf` and `out/soucasna_kronika_v2_0_0.pdf`.
- The temporary export was removed after the checks passed.

## OpenSpec

- This installed CLI does not support `openspec validate --change migrate-chronicles-to-typst`; it reports `unknown option '--change'`.
- The supported change-specific equivalent, `openspec validate migrate-chronicles-to-typst --type change --strict --no-interactive`, passed.
