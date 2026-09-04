#import "../../shared/publication.typ": image-sequence, pdf-page-range

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
  pdf-page-range("/scans/nova_kronika_scans.pdf", 11, 36)

  image-sequence((
    "/scans/2025_05/IMG_20250321_105914.jpg",
    "/scans/2025_05/IMG_20250321_110010.jpg",
    "/scans/2025_05/IMG_20250321_110058.jpg",
    "/scans/2025_05/IMG_20250321_110152.jpg",
  ))
}
