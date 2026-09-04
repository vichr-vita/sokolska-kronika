# Stable LaTeX baseline

Captured on 2026-09-04 with pdfTeX 3.141592653-2.6-1.40.29 (TeX Live 2026/Arch Linux), Poppler 26.07.0, and qpdf 12.4.0.

Each entry point was built in its own empty directory with:

```sh
pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$work" "$entry"
```

After every pass, SHA-256 was calculated over the entry point's `.aux` and `.toc`. `stara_kronika_main.tex` changed between passes 1 and 2, then pass 3 matched pass 2. `nova_kronika_main.tex` matched after pass 2. Final logs contain no undefined-reference or rerun warnings, and `qpdf --check` reports no syntax or stream errors.

The stable pre-war PDF has 145 letter-size pages. The stable contemporary PDF has 53 letter-size pages. These counts are diagnostic baselines, not migration pass conditions.

Files in this directory record:

- stable contents entries and destination pages;
- source media references, expanded where LaTeX loops generate multiple files;
- external URLs and PDF destination/bookmark counts;
- all lists, term-label blocks, tables, quotations, verse, callouts, and explicit line breaks found in source;
- UTF-8 text extracted by `pdftotext`;
- representative rendered pages selected in `review-pages.md` and combined into compact contact sheets.

`manifest.json` pins source, stable-state, PDF, and extracted-text checksums. PDF checksums identify this capture; PDF creation dates make rebuilt files byte-different.
