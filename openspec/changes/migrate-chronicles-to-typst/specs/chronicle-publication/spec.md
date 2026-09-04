## Purpose

Define how contributors build and maintain both digital chronicle editions while readers receive complete, readable, and navigable PDF documents.

## ADDED Requirements

### Requirement: Both chronicle editions can be built
The project SHALL provide one documented command that builds the pre-war and contemporary chronicles from Typst sources. A successful build SHALL create `out/predvalecna_kronika_v2_0_0.pdf` and `out/soucasna_kronika_v2_0_0.pdf`, and a failed compilation SHALL cause the command to return a non-zero exit status.

#### Scenario: Complete build succeeds
- **WHEN** a contributor runs the build command with the documented Typst version and all tracked source assets present
- **THEN** the command exits successfully and creates both versioned PDF files

#### Scenario: One edition cannot compile
- **WHEN** an edition contains invalid markup or references a missing asset
- **THEN** the build command exits with a non-zero status and identifies the failed compilation

### Requirement: Published content survives the migration
Each Typst edition SHALL retain the words, punctuation, emphasis, lists, term labels, tables, quotations, verse lineation, intentional line breaks, symbols, section order, links, captions, images, and scanned pages from its LaTeX edition. Table labels and values SHALL keep their row and column associations. The only planned wording change is replacing LaTeX with Typst in each edition's typesetting credit while leaving the surrounding author statement unchanged. The migration SHALL NOT otherwise modernize or copy-edit historical text unless a correction is reviewed separately.

#### Scenario: Pre-war chronicle content is compared
- **WHEN** a reviewer compares the Typst pre-war edition with the current LaTeX source and PDF
- **THEN** every source section from the introductory pages through the 1934 jubilee is present in the same order with its associated media

#### Scenario: Contemporary chronicle content is compared
- **WHEN** a reviewer compares the Typst contemporary edition with the current LaTeX source and PDF
- **THEN** its introductory text, historical overview, scan pages 1 through 36, and four May 2025 photographs are present in the intended order without cropping or distortion

#### Scenario: Structured historical content is compared
- **WHEN** a reviewer compares a table, quotation, poem, or block with intentional line breaks against the LaTeX source and stable rendered baseline
- **THEN** its labels, values, nesting, symbols, and lineation preserve the source relationships

### Requirement: PDFs remain readable and navigable
Each edition SHALL declare Czech as its document and text language and SHALL have a legible Czech text layout, Czech hyphenation and quotation behavior, localized generated labels, consistent heading hierarchy, page numbers, running context outside full-page media, a visible table of contents, PDF bookmarks, and working internal and external links. Full-page images and scanned PDF pages SHALL fit within the page without changing their aspect ratio.

#### Scenario: Reader uses document navigation
- **WHEN** a reader opens either PDF in a viewer that supports links and bookmarks
- **THEN** the contents entries and bookmark tree lead to the corresponding sections, external links retain their targets, and page numbers and running headings identify ordinary content pages

#### Scenario: Reader views Czech typesetting
- **WHEN** a reader opens typeset Czech prose or a generated contents heading
- **THEN** Czech glyphs, hyphenation, quotation marks, localized labels, and PDF language metadata identify and render the content as Czech

#### Scenario: Reader views source media
- **WHEN** a reader opens a page containing an image or an embedded scan
- **THEN** the entire source page or image is visible at a useful size without stretching or unintended clipping

### Requirement: Chronicle sources remain easy to edit
The project SHALL keep normal prose in native Typst markup, centralize shared presentation rules, and divide each edition into clearly named files at logical content boundaries. The pre-war chronology SHALL keep each year section intact while grouping years into reviewable period files. Edition entry points SHALL describe document assembly without duplicating the shared layout.

#### Scenario: Contributor edits historical prose
- **WHEN** a contributor opens a period file to change a paragraph, heading, list, emphasis, link, or quotation
- **THEN** the surrounding source is readable without tracing LaTeX commands or repeated layout configuration

#### Scenario: Contributor changes shared presentation
- **WHEN** a contributor changes a shared page, heading, contents, link, image, or callout rule
- **THEN** both editions receive the change without copying that rule between their entry points

### Requirement: Maintenance workflow is documented
The repository SHALL document the required Typst version, source directory layout, build command, output names, shared helpers, content conventions, and the process for adding text, images, or scanned pages.

#### Scenario: New contributor prepares an edit
- **WHEN** a contributor reads the project documentation
- **THEN** they can identify the correct source file, make a conventional content edit, and build both PDFs without consulting the removed LaTeX implementation
