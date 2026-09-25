# Kronika TJ Sokol Poruba

Repozitář obsahuje zdrojové texty a média pro dvě digitální kroniky TJ Sokol Poruba:

- předválečnou kroniku od založení jednoty do roku 1934;
- současnou kroniku, která spojuje sazbu textu, stránky zdrojového PDF a fotografie.

Obě vydání používají společnou sazbu v Typstu a vznikají jako samostatné PDF soubory.

## Požadavky

Projekt je testován s CLI nástrojem [Typst 0.15.1](https://github.com/typst/typst/releases/tag/v0.15.1). Nainstalujte přesně tuto verzi podle [oficiálních pokynů](https://github.com/typst/typst#installation) a zpřístupněte příkaz `typst` v proměnné `PATH`.

Verzi ověříte příkazem:

```sh
typst --version
```

Výstup musí začínat `typst 0.15.1`.

## Sestavení

V kořeni repozitáře spusťte:

```sh
./build.sh
```

Skript přejde do kořene repozitáře, odstraní případné zastaralé cílové soubory a sestaví obě vydání s volbou `--root .`. Při chybějícím Typstu nebo chybě překladu skončí nenulovým návratovým kódem a označí neúspěšný překlad.

Úspěšné sestavení vytvoří:

```text
out/predvalecna_kronika_v3_0_0.pdf
out/soucasna_kronika_v3_0_0.pdf
```

Verze 3 označuje vydání sázená v Typstu místo LaTeXu.

Jedno vydání lze při práci přeložit přímo z kořene repozitáře:

```sh
typst compile --root . chronicles/predvalecna/main.typ /tmp/predvalecna.pdf
typst compile --root . chronicles/soucasna/main.typ /tmp/soucasna.pdf
```

## Uspořádání zdrojů

```text
chronicles/
  shared/publication.typ          společná sazba a mediální pomocné funkce
  predvalecna/
    main.typ                      pořadí částí předválečného vydání
    content/front-matter.typ      titulní a úvodní část
    content/1894-1900.typ         úplné roční oddíly podle období
    content/...
  soucasna/
    main.typ                      pořadí částí současného vydání
    content/front-matter.typ      titul, obsah, úvod a slovo autora
    content/historical-overview.typ
    content/scans.typ             rozsahy PDF a fotografie
images/                           obrazové podklady
scans/                            zdrojové skeny, PDF a fotografie
verification/                     kontrolní skripty a zachycené výsledky
out/                              sestavená PDF, nesledovaná Gitem
```

Soubory `main.typ` pouze nastavují metadata vydání a skládají obsah ve výsledném pořadí. Běžný text patří do pojmenovaných souborů v příslušném adresáři `content/`; pravidla společné sazby patří do `chronicles/shared/publication.typ`.

## Společné funkce

Modul `chronicles/shared/publication.typ` poskytuje:

- `publication`: česká metadata a jazyk textu, formát A4, okraje, písmo, nadpisy, odkazy, záhlaví a čísla stran;
- `publication-outline()`: lokalizovaný obsah s interními odkazy;
- `title-page(...)`: titulní stranu s volitelným obrazem, označením vydání a datem;
- `full-page-image(source, page-number: none)`: jeden obraz nebo jednu stránku PDF na celou výstupní stranu;
- `pdf-page-range(source, start, end)`: všechny stránky uzavřeného, jednotkově číslovaného rozsahu od `start` do `end` včetně;
- `image-sequence(sources)`: posloupnost samostatných celostránkových obrazů;
- `newspaper-clipping(body)`: rámeček novinového výstřižku;
- `verse(body)`: verše se zachovanými konci řádků.

Celostránkové funkce používají `fit: "contain"`: zobrazí celé médium, zachovají poměr stran a nic neoříznou.

## Úpravy textu

Pište běžný obsah přímo v nativní syntaxi Typstu. Používejte `=`, `==` a `===` pro stávající úrovně nadpisů, `_kurzívu_`, `*tučné písmo*`, `#quote[...]` pro citace a `#link("https://...")[text]` pro odkazy. Záměrný konec řádku zapisujte zpětným lomítkem na konci řádku.

Zachovejte původní znění, interpunkci, mezery s významem, zvýraznění, pořadí, seznamy, popisky, tabulkové vazby, vnoření citací, verše a symboly. Historický text bez samostatně schválené opravy nemodernizujte ani stylisticky neupravujte. V předválečném vydání nepřesouvejte část jednoho roku mezi soubory období.

Po přidání nebo přejmenování nadpisu zkontrolujte jeho pořadí v obsahu a záložkách PDF. Odkaz zapisujte jako skutečný prvek `link`, ne pouze jako viditelnou adresu.

## Obrázky a skeny

Cesty k médiím začínají lomítkem a jsou relativní ke kořeni předanému volbou `--root .`, například `/images/cover.jpg` nebo `/scans/nova_kronika_scans.pdf`. Nové podklady ukládejte do věcně odpovídajícího podadresáře `images/` nebo `scans/`; nevkládejte je mezi zdroje v `chronicles/`.

Pro samostatný celostránkový obrázek použijte `full-page-image`; pro několik obrázků v daném pořadí použijte `image-sequence`. Neupravujte poměr stran, nepoužívejte ořez a nenahrazujte zdroj rastrovou kopií jen kvůli sazbě.

Stránky zdrojového PDF vkládejte přímo:

```typ
#pdf-page-range("/scans/nova_kronika_scans.pdf", 4, 10)
```

Čísla jsou jednotková a oba konce rozsahu jsou zahrnuty. Navazující úseky zapisujte jako samostatná volání u příslušných oddílů, aby zůstaly zřejmé hranice a pořadí. PDF před vložením nerasterizujte.

## Kontroly

Po změně sestavte obě vydání pomocí `./build.sh`. Zaměřené kontroly PDF lze spustit takto:

```sh
ruby verification/typst-prewar/verify_pdf.rb out/predvalecna_kronika_v3_0_0.pdf
ruby verification/typst-contemporary/verify.rb out/soucasna_kronika_v3_0_0.pdf
```

Kontroly současného vydání navíc ověřují text, nadpisy, odkaz, zvýraznění, rozsahy skenů a pořadí vložených stran. Před odevzdáním vizuálně projděte změněné textové strany, hranice celostránkových médií a poslední stranu.
