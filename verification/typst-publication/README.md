# Typst publication layer proof

Compile the focused fixture from the repository root with Typst 0.15.1:

```sh
typst compile --root . verification/typst-publication/publication-api.typ /tmp/publication-api.pdf
```

The compiled fixture provides this evidence:

- `qpdf --check` reports no syntax or stream encoding errors for the eight-page A4 PDF.
- The PDF catalog contains `/Lang (cs)`, and extracted text contains Czech glyphs, smart quotes, the localized `Obsah` title, running context, and page numbers on ordinary pages.
- The PDF has a nested bookmark tree, linked outline entries, and the retained external GitHub URL.
- The title page, one standalone full-page image, source-PDF pages 1 and 2, and two standalone sequence images compile through the shared helpers.
- `pdfimages -list` reports the embedded scan pages with the same pixel dimensions, encoding, color data, and compressed sizes as source pages 1 and 2. They were embedded directly rather than rasterized again.
- Full-page media pages contain no extracted header or page-number text. Every media helper calls `image` with `fit: "contain"`, so Typst fits each item without changing its aspect ratio or clipping it.
