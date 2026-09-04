#import "../../shared/publication.typ": publication-outline, title-page

#let today = datetime.today()
#let months = (
  "ledna", "února", "března", "dubna", "května", "června",
  "července", "srpna", "září", "října", "listopadu", "prosince",
)

#title-page(
  [Předválečná kronika],
  subtitle: [TJ Sokol Poruba],
  image-source: "/images/cover.jpg",
  edition: [Digitální vydání],
  date: [#today.day(). #months.at(today.month() - 1) #today.year()],
)

#publication-outline()

#include "front-matter-body.typ"
