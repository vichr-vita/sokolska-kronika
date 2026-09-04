# Typst 0.15.1 tooling proof

Typst 0.15.1 (`9dfd3a08`) is the selected reproducible release. The existing local installation was used; `typst --version` and the binary checksum are recorded below. `Libertinus Serif`, shipped in Typst's embedded font set, avoids a machine-specific system font dependency and contains the tested Czech glyphs.

Compile from repository root:

```sh
typst compile --root . verification/typst-tooling/czech-and-pdf-embedding.typ /tmp/typst-tooling-proof.pdf
```

Acceptance evidence:

- compilation exits zero with Typst 0.15.1;
- output has two A4 pages and passes `qpdf --check`;
- extracted page 1 contains Czech diacritics, localized `Obsah`, Czech smart quotes, and Czech hyphenation (`Nejneobhospodařo- / vávatelnějšími`, with a PDF soft hyphen);
- PDF catalog language is `cs`;
- page 2 has the same dimensions as source scan page 1 and retains that page's original JPEG object rather than producing a derived page raster;
- `pdfimages -list` reports one JPEG on source page 1 and proof page 2. Both are 2331x3596 px, ICC RGB, 8 bpc, 317 dpi, and 1992 KiB.

The proof source directly calls `image(..., page: 1, fit: "contain")` on `scans/nova_kronika_scans.pdf`. No rasterization step or derived scan asset exists.

Binary SHA-256: `29273eaa04f6d00edd0c2bec578f565fc9c65be856bfbffc894567c68ed0b237`.

Proof PDF SHA-256: `73afb6d99ea3c79bdcc0ff189c3645fd091052199fae83dc6ecde9244129ea48`.
