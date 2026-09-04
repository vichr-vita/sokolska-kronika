#let sokol-red = rgb("#8b0000")
#let dark-gray = rgb("#3c3c3c")
#let link-blue = rgb("#005ea8")

#let publication(body, title: none, author: "TJ Sokol Poruba", running-title: none) = {
  set document(title: title, author: author)
  set page(
    paper: "a4",
    binding: left,
    margin: (top: 24mm, bottom: 22mm, inside: 25mm, outside: 21mm),
    header-ascent: 12mm,
    footer-descent: 12mm,
    header: context {
      let current-page = counter(page).get().first()
      let all-headings = query(selector(heading))
      let page-headings = all-headings.filter(item => item.location().page() == current-page)
      let previous-headings = all-headings.filter(item => item.location().page() < current-page)
      let current = if page-headings.len() > 0 {
        page-headings.first().body
      } else if previous-headings.len() > 0 {
        previous-headings.last().body
      } else {
        running-title
      }

      if current != none {
        set text(size: 9pt, fill: dark-gray)
        set par(justify: false)
        align(center, current)
      }
    },
    numbering: "1",
    number-align: center + bottom,
  )
  set text(
    font: "Libertinus Serif",
    lang: "cs",
    size: 11pt,
    hyphenate: true,
  )
  set par(
    justify: true,
    leading: 0.68em,
    spacing: 0.72em,
    first-line-indent: 1em,
  )
  set heading(numbering: none, outlined: true, bookmarked: true)

  show heading: set par(first-line-indent: 0pt, justify: false)
  show heading.where(level: 1): set block(above: 20pt, below: 14pt)
  show heading.where(level: 1): set text(size: 22pt, weight: "bold", fill: sokol-red)
  show heading.where(level: 2): set block(above: 16pt, below: 9pt)
  show heading.where(level: 2): set text(size: 16pt, weight: "bold", fill: sokol-red)
  show heading.where(level: 3): set block(above: 12pt, below: 7pt)
  show heading.where(level: 3): set text(size: 13pt, weight: "bold", fill: dark-gray)
  show outline.entry.where(level: 1): set text(weight: "bold")
  show link: set text(fill: link-blue)
  show link: underline

  body
}

#let publication-outline() = {
  pagebreak(weak: true)
  outline(title: [Obsah], depth: 3)
  pagebreak()
}

#let title-page(
  title,
  subtitle: none,
  image-source: none,
  edition: none,
  date: none,
) = page(
  paper: "a4",
  margin: 22mm,
  header: none,
  footer: none,
  numbering: none,
)[
  #set par(justify: false, first-line-indent: 0pt)
  #align(center)[
    #v(12mm)
    #text(size: 30pt, weight: "bold", fill: sokol-red)[#title]
    #if subtitle != none {
      v(8mm)
      text(size: 18pt, weight: "bold", subtitle)
    }
    #if image-source != none {
      v(16mm)
      image(image-source, width: 100%, height: 125mm, fit: "contain")
    }
    #if edition != none {
      v(12mm)
      text(size: 13pt, edition)
    }
    #if date != none {
      v(5mm)
      text(size: 11pt, date)
    }
  ]
]

#let full-page-image(source, page-number: none) = page(
  paper: "a4",
  margin: 0pt,
  header: none,
  footer: none,
  numbering: none,
)[
  #if page-number == none {
    image(source, width: 100%, height: 100%, fit: "contain")
  } else {
    image(source, page: page-number, width: 100%, height: 100%, fit: "contain")
  }
]

#let pdf-page-range(source, start, end) = {
  for page-number in range(start, end, inclusive: true) {
    full-page-image(source, page-number: page-number)
  }
}

#let image-sequence(sources) = {
  for source in sources {
    full-page-image(source)
  }
}

#let newspaper-clipping(body) = block(
  width: 100%,
  breakable: true,
  inset: 10pt,
  radius: 2pt,
  fill: luma(248),
  stroke: 0.5pt + luma(145),
)[
  #set text(size: 9.5pt)
  #set par(first-line-indent: 0pt)
  #text(size: 8pt, weight: "bold", fill: dark-gray)[Novinový výstřižek]
  #v(5pt)
  #body
]

#let verse(body) = block(
  inset: (left: 2em),
  width: 100%,
)[
  #set par(first-line-indent: 0pt, justify: false, spacing: 0pt)
  #body
]
