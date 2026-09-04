#import "../../chronicles/shared/publication.typ": publication, publication-outline, title-page, full-page-image, pdf-page-range, image-sequence, newspaper-clipping

#show: publication.with(
  title: "Ověření společné publikační vrstvy",
  running-title: "Ověření publikační vrstvy",
)

#title-page(
  [Ověření společné publikační vrstvy],
  subtitle: [TJ Sokol Poruba],
  image-source: "../../images/cover.jpg",
  edition: [Zkušební vydání],
  date: [2026],
)

#publication-outline()

= České prostředí a navigace

Příliš žluťoučký kůň úpěl ďábelské ódy. "Řeřicha, Ústí a čtyři." Odkaz vede na #link("https://github.com/vichr-vita/sokolska-kronika")[zdroj projektu].

== Vložený text

#newspaper-clipping[
  Dobový tisk zůstává běžným obsahem Typstu. Pomocná funkce určuje pouze vzhled rámečku.
]

#full-page-image("../../images/cover.jpg")

#pdf-page-range("../../scans/nova_kronika_scans.pdf", 1, 2)

#image-sequence((
  "../../scans/2025_05/IMG_20250321_105914.jpg",
  "../../scans/2025_05/IMG_20250321_110010.jpg",
))
