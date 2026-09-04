#import "../../shared/publication.typ": publication-outline, title-page
#import "scans.typ": introductory-pages

#let today = datetime.today()
#let months = (
  "ledna", "února", "března", "dubna", "května", "června",
  "července", "srpna", "září", "října", "listopadu", "prosince",
)

#title-page(
  [Současná kronika],
  subtitle: [TJ Sokol Poruba],
  image-source: "/images/cover.jpg",
  edition: [Digitální vydání],
  date: [#today.day(). #months.at(today.month() - 1) #today.year()],
)

#publication-outline()

= Úvodní slovo kronikáře TJ Sokol Poruba

#introductory-pages()

= Slovo autora sazby digitální kroniky

Digitální kronika, kterou nyní čtete, je výsledkem dobrovolnické práce nadšených jedinců. Jako autor digitální sazby mám tu čest být zodpovědný za technickou produkci tohoto digitálního dokumentu, jeho následné uveřejnění a aktualizování.

Jelikož se jedná o především digitální dokument, obsah je interaktivní. Ve většině prohlížečů přenositelných digitálních dokumentů (PDF) můžete při kliknutí na položku v obsahu přejít hned na sekci v kronice. Většina prohlížečů dále umožňuje obsah zobrazit zároveň s textem jakožto „průvodce“. V průvodci interaktivita funguje obdobně.

Projekt je dostupný na stránce #link("https://github.com/vichr-vita/sokolska-kronika")[GitHub] (#text(style: "italic")[#raw("https://github.com/vichr-vita/sokolska-kronika")]), která umožňuje poskytnutí technické zpětné vazby a návrhů na úpravu. Velmi si vážím jakékoliv zpětné vazby, která by mohla přispět k dalšímu zlepšení sazby a celkového vzhledu dokumentu. Vaše názory a návrhy jsou vítány a mohou být zaslány prostřednictvím GitHubu. V~případě jiných dotazů je možné psát i na email #text(style: "italic")[me#sym.at#h(0pt)vichr.me].

Toto dílo vzniká za použití volně dostupného open-source jazyka pro typografické zpracování a sazbu, LaTeX. Děkuji všem, kteří se na tomto projektu podílejí, a doufám, že vám digitální kronika přinese mnoho užitečných informací a radosti.

#v(1cm)
S úctou a sokolským „Nazdar!“, \
Vít Chrubasík

#pagebreak()
