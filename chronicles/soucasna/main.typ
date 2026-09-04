#import "../shared/publication.typ": publication
#import "content/scans.typ": chronicle-pages

#show: publication.with(
  title: "Současná kronika",
  running-title: "Současná kronika",
)

#include "content/front-matter.typ"
#include "content/historical-overview.typ"
#chronicle-pages()
