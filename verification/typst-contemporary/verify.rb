#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "open3"

ROOT = File.expand_path("../..", __dir__)
MAIN_TEX = File.join(ROOT, "nova_kronika_main.tex")
OVERVIEW_TEX = File.join(ROOT, "nova_kronika_historicky_prehled_klos.tex")
CONTENT = File.join(ROOT, "chronicles/soucasna/content")
MANIFEST = File.join(ROOT, "verification/latex-baseline/manifest.json")
REPORT = File.join(__dir__, "verification.json")
PDF = File.expand_path(ARGV.fetch(0, "/tmp/opencode/soucasna.pdf"))

def run(*command)
  stdout, stderr, status = Open3.capture3(*command)
  abort "#{command.join(' ')} failed:\n#{stderr}" unless status.success?
  stdout.force_encoding("UTF-8")
end

def normalize(text)
  text.unicode_normalize(:nfc).gsub("~", " ").gsub(/[\u00a0\u202f\u2060]/, " ").gsub(/[[:space:]]+/, " ").strip
end

def latex_inline(text)
  value = text.dup
  value.gsub!(/\\href\{([^{}]+)\}\{([^{}]+)\}/, "\\2")
  loop do
    before = value.dup
    value.gsub!(/\\enquote\{([^{}]*)\}/, '„\1“')
    value.gsub!(/\\emph\{([^{}]*)\}/, "\\1")
    break if value == before
  end
  value.gsub!(/\\LaTeX\b/, "LaTeX")
  value.gsub!(/\\noindent\b/, "")
  value.gsub!(/\\\\/, " ")
  normalize(value)
end

def typst_inline(text)
  value = text.dup
  value.gsub!(/#text\(style: "italic"\)\[#raw\("([^"]*)"\)\]/, "\\1")
  value.gsub!(/#text\(style: "italic"\)\[me#sym\.at#h\(0pt\)vichr\.me\]/, "me@vichr.me")
  value.gsub!(/#link\("[^"]+"\)\[([^\]]*)\]/, "\\1")
  value.gsub!(/#quote\[([^\]]*)\]/, '„\1“')
  value.gsub!(/#raw\("([^"]*)"\)/, "\\1")
  value.gsub!(/#(?:v|h)\([^)]*\)/, "")
  value.gsub!(/\\\s*$/, "")
  normalize(value)
end

def source_headings(main_lines, overview_lines)
  lines = [main_lines[116], main_lines[125]] + overview_lines + [main_lines[149], main_lines[161]]
  lines.filter_map do |line|
    match = line.match(/\\(section|subsection)\*?\{(.*)\}/)
    { "level" => match[1] == "section" ? 1 : 2, "title" => latex_inline(match[2]) } if match
  end
end

def typst_headings(lines)
  lines.filter_map do |line|
    if (match = line.match(/^(={1,2})\s+(.*)$/))
      { "level" => match[1].length, "title" => typst_inline(match[2]) }
    elsif (match = line.match(/^\s*heading\(level:\s*([12])\)\[(.*)\]/))
      { "level" => match[1].to_i, "title" => typst_inline(match[2]) }
    end
  end
end

def prose(lines, converter)
  normalize(lines.filter_map do |line|
    stripped = line.strip
    next if stripped.empty? || stripped.start_with?("//", "#set", "#show", "#v", "#pagebreak")
    next if stripped.match?(/^={1,2}\s/) || stripped.match?(/^\\(?:section|subsection)/)
    next if stripped.match?(/^\\(?:phantomsection|addcontentsline|markright)/)

    converter.call(stripped)
  end.join(" "))
end

def flatten_outlines(items)
  items.flat_map { |item| [item] + flatten_outlines(item.fetch("kids", [])) }
end

def image_rows(output)
  output.lines.filter_map do |line|
    fields = line.split
    next unless fields[0]&.match?(/^\d+$/) && fields[1]&.match?(/^\d+$/) && fields[2] == "image"

    { "page" => fields[0].to_i, "width" => fields[3].to_i, "height" => fields[4].to_i,
      "color" => fields[5], "components" => fields[6].to_i, "bits" => fields[7].to_i, "encoding" => fields[8] }
  end
end

abort "missing or empty PDF: #{PDF}" unless File.file?(PDF) && File.size(PDF).positive?

manifest = JSON.parse(File.read(MANIFEST, encoding: "UTF-8"))
main_lines = File.readlines(MAIN_TEX, chomp: true, encoding: "UTF-8")
overview_lines = File.readlines(OVERVIEW_TEX, chomp: true, encoding: "UTF-8")
front_lines = File.readlines(File.join(CONTENT, "front-matter.typ"), chomp: true, encoding: "UTF-8")
historical_lines = File.readlines(File.join(CONTENT, "historical-overview.typ"), chomp: true, encoding: "UTF-8")
scan_lines = File.readlines(File.join(CONTENT, "scans.typ"), chomp: true, encoding: "UTF-8")

expected_hashes = manifest.fetch("soucasna").fetch("sourceSha256")
hashes = {
  "nova_kronika_main.tex" => Digest::SHA256.file(MAIN_TEX).hexdigest,
  "nova_kronika_historicky_prehled_klos.tex" => Digest::SHA256.file(OVERVIEW_TEX).hexdigest,
  "scans/nova_kronika_scans.pdf" => Digest::SHA256.file(File.join(ROOT, "scans/nova_kronika_scans.pdf")).hexdigest,
}

front_source = prose([main_lines[130], main_lines[132], main_lines[134], main_lines[136], main_lines[139], main_lines[140]], method(:latex_inline))
front_typst = prose(front_lines[25..35], method(:typst_inline))
overview_source = prose(overview_lines, method(:latex_inline))
overview_typst = prose(historical_lines, method(:typst_inline))
expected_headings = source_headings(main_lines, overview_lines)
actual_headings = typst_headings(front_lines + historical_lines + scan_lines)

source_emphasis = main_lines.filter_map { |line| line.scan(/\\emph\{([^{}]*)\}/).flatten }.flatten
typst_emphasis = front_lines.flat_map do |line|
  values = line.scan(/#text\(style: "italic"\)\[#raw\("([^"]*)"\)\]/).flatten
  values << "me@vichr.me" if line.include?('#text(style: "italic")[me#sym.at#h(0pt)vichr.me]')
  values
end
source_links = main_lines.filter_map { |line| line[/\\href\{([^{}]+)\}/, 1] }
typst_links = front_lines.filter_map { |line| line[/#link\("([^"]+)"\)/, 1] }

source_ranges = main_lines.filter_map do |line|
  match = line.match(/\\includepdf\[pages=(\d+)-(\d+)[^\]]*\]\{scans\/nova_kronika_scans\.pdf\}/)
  [match[1].to_i, match[2].to_i] if match
end
typst_ranges = scan_lines.join("\n").scan(/pdf-page-range\(\s*"\/scans\/nova_kronika_scans\.pdf",\s*(\d+),\s*(\d+)/m).map { |range| range.map(&:to_i) }
photo_ids = main_lines.join("\n")[/\\foreach \\imgfile in \{([^}]+)\}/, 1].split(",")
source_photos = photo_ids.map { |id| "scans/2025_05/IMG_20250321_#{id}.jpg" }
typst_photos = scan_lines.filter_map { |line| line[%r{"/(scans/2025_05/[^"]+\.jpg)"}, 1] }

qpdf_check = run("qpdf", "--check", PDF)
pdfinfo = run("pdfinfo", PDF)
pdf_json_text = run("qpdf", "--json", PDF)
pdf = JSON.parse(pdf_json_text)
outlines = flatten_outlines(pdf.fetch("outlines"))
outline_titles = outlines.map { |item| item.fetch("title") }
catalog = pdf.fetch("qpdf").fetch(1).values.filter_map { |entry| entry["value"] if entry["value"].is_a?(Hash) }.find { |value| value["/Type"] == "/Catalog" }
link_count = pdf.fetch("qpdf").fetch(1).values.count do |entry|
  entry["value"].is_a?(Hash) && entry["value"]["/Subtype"] == "/Link"
end

output_images = image_rows(run("pdfimages", "-list", PDF))
source_scan_images = image_rows(run("pdfimages", "-list", File.join(ROOT, "scans/nova_kronika_scans.pdf")))
embedded_scans = output_images[1, 36]
scan_signature = ->(row) { row.values_at("width", "height", "color", "components", "bits", "encoding") }
photo_dimensions = source_photos.map do |path|
  run("identify", "-format", "%w %h", File.join(ROOT, path)).split.map(&:to_i)
end
embedded_photo_dimensions = output_images.last(4).map { |row| row.values_at("width", "height") }

expected_media_pages = (4..6).to_a + (12..18).to_a + (20..49).to_a
ordinary_page = run("pdftotext", "-layout", "-f", "7", "-l", "7", PDF, "-")
media_text = expected_media_pages.flat_map do |page|
  run("pdftotext", "-f", page.to_s, "-l", page.to_s, PDF, "-").strip.empty? ? [] : [page]
end

checks = {
  "frozenSources" => hashes == expected_hashes,
  "titlePage" => front_lines.join("\n").include?("[Současná kronika]") && front_lines.join("\n").include?("subtitle: [TJ Sokol Poruba]") && front_lines.join("\n").include?("edition: [Digitální vydání]"),
  "frontMatterText" => front_source == front_typst,
  "historicalOverviewText" => overview_source == overview_typst,
  "headingHierarchy" => expected_headings == actual_headings,
  "emphasis" => source_emphasis == typst_emphasis,
  "externalLinks" => source_links == typst_links,
  "intentionalLineBreak" => main_lines[139].end_with?("\\\\") && front_lines[34].end_with?("\\"),
  "scanRanges" => source_ranges == typst_ranges && typst_ranges == [[1, 3], [4, 10], [11, 36]],
  "photoOrder" => source_photos == typst_photos,
  "qpdfClean" => qpdf_check.include?("No syntax or stream encoding errors found"),
  "typstVersion" => pdfinfo.include?("Creator:         Typst 0.15.1"),
  "documentMetadata" => pdfinfo.include?("Title:           Současná kronika") && pdfinfo.include?("Author:          TJ Sokol Poruba"),
  "czechLanguage" => catalog && catalog["/Lang"] == "u:cs",
  "a4Pages" => pdfinfo.include?("Page size:       595.276 x 841.89 pts (A4)"),
  "outlineOrder" => outline_titles == ["Obsah"] + expected_headings.map { |heading| heading["title"] },
  "contentsLinks" => link_count >= outlines.length,
  "externalLinkInPdf" => pdf_json_text.include?("https://github.com/vichr-vita/sokolska-kronika"),
  "scanBoundaries" => output_images.drop(1).map { |image| image["page"] } == expected_media_pages,
  "directScanEmbedding" => embedded_scans.map(&scan_signature) == source_scan_images.map(&scan_signature),
  "photoDimensions" => embedded_photo_dimensions == photo_dimensions,
  "ordinaryHeaderAndNumber" => ordinary_page.scan("Slovo autora sazby digitální kroniky").length >= 2 && ordinary_page.match?(/\b7\s*\z/),
  "mediaPagesWithoutHeaders" => media_text.empty?,
  "finalImage" => output_images.last["page"] == pdf.fetch("pages").length && output_images.last.values_at("width", "height") == photo_dimensions.last,
}

report = {
  "pdf" => File.basename(PDF),
  "bytes" => File.size(PDF),
  "pages" => pdf.fetch("pages").length,
  "outlineEntries" => outlines.length,
  "linkAnnotations" => link_count,
  "scanRanges" => typst_ranges,
  "photos" => typst_photos,
  "checks" => checks,
  "allPassed" => checks.values.all?,
}
File.write(REPORT, JSON.pretty_generate(report) + "\n", encoding: "UTF-8")
puts JSON.pretty_generate(report)
exit(report["allPassed"] ? 0 : 1)
