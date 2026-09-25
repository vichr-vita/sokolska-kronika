#import "../../shared/publication.typ": pdf-page-range

#let introductory-pages() = pdf-page-range(
  "/scans/nova_kronika_scans.pdf",
  1,
  3,
)

#let chronicle-pages() = {
  pagebreak(weak: true)
  heading(level: 1)[Výběr z rodinné kroniky Bártů]
  pdf-page-range("/scans/nova_kronika_scans.pdf", 4, 10)

  heading(level: 1)[Současná kronika]
  pdf-page-range("/scans/nova_kronika_scans.pdf", 11, 20)
  pdf-page-range("/scans/2026_07/kronika_2023-2025.pdf", 1, 1)
  // These two pages fall between pages 1 and 2 of the newer scan.
  pdf-page-range("/scans/nova_kronika_scans.pdf", 22, 23)
  pdf-page-range("/scans/2026_07/kronika_2023-2025.pdf", 2, 24)
  pdf-page-range("/scans/2026_07/kronika_2026.pdf", 1, 7)
}
