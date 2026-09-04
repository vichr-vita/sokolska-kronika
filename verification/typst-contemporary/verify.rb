#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "open3"

ROOT = File.expand_path("../..", __dir__)
CONTENT = File.join(ROOT, "chronicles/soucasna/content")
SECTIONS = File.join(ROOT, "verification/latex-baseline/soucasna-sections.txt")
REPORT = File.join(__dir__, "verification.json")
PDF = File.expand_path(ARGV.fetch(0, "/tmp/opencode/soucasna.pdf"))

# These hashes bind current checks to the source set that passed the frozen LaTeX comparison.
ACCEPTED_SOURCE_SHA256 = {
  "chronicles/shared/publication.typ" => "2081259256d1d975947ae89016835489d3278796614f328fc421c4ec9cdfda6f",
  "chronicles/soucasna/main.typ" => "4e8d023f00ac3fcf3291df0e0de1ed3fd8b744aa59aa00646e093bed6a3a920e",
  "chronicles/soucasna/content/front-matter.typ" => "716ff1e18682b54e866b750a11069dfa8e950404177be0b2e07e7946d3a9ef20",
  "chronicles/soucasna/content/historical-overview.typ" => "f753da1279d786f69f05f1daa21d9eece93ad299fb223ef745b558f34ec3ecbb",
  "chronicles/soucasna/content/scans.typ" => "8f3d6a958930cf1f53aa39afb287c2b69ad88e8664df3697c9a8bc58a7bb48ce",
}.freeze
ACCEPTED_CREDIT_SOURCE_SHA256 = "0af94f866ea00c3e4072a2f268773952e421af8530ce15287b1c907b03cec5be"
ACCEPTED_CREDIT_TYPST_SHA256 = "e2b7b4ee2e9bdeb376a397a36b6346e9ec3108b3f73a06b7ac70fd2a203f6a94"
ACCEPTED_SCAN_SHA256 = "293ff2ce7d7209c13067da93d0149d017e89305ef3a9b0d31a01aa44f3cd807f"
ACCEPTED_SCAN_RANGES = [[1, 3], [4, 10], [11, 36]].freeze
ACCEPTED_PHOTOS = %w[
  scans/2025_05/IMG_20250321_105914.jpg
  scans/2025_05/IMG_20250321_110010.jpg
  scans/2025_05/IMG_20250321_110058.jpg
  scans/2025_05/IMG_20250321_110152.jpg
].freeze

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
    value.gsub!(/\\enquote\s*\{([^{}]*)\}/, '„\1“')
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

def typst_headings(lines)
  lines.filter_map do |line|
    if (match = line.match(/^(={1,2})\s+(.*)$/))
      { "level" => match[1].length, "title" => typst_inline(match[2]) }
    elsif (match = line.match(/^\s*heading\(level:\s*([12])\)\[(.*)\]/))
      { "level" => match[1].to_i, "title" => typst_inline(match[2]) }
    end
  end
end

def baseline_headings(path)
  File.readlines(path, chomp: true, encoding: "UTF-8").filter_map do |line|
    match = line.match(/\A\\contentsline \{(section|subsection)\}\{(.*)\}\{\d+\}\{section\*\.\d+\}%\z/)
    next unless match

    { "level" => match[1] == "section" ? 1 : 2, "title" => latex_inline(match[2]) }
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

front_lines = File.readlines(File.join(CONTENT, "front-matter.typ"), chomp: true, encoding: "UTF-8")
historical_lines = File.readlines(File.join(CONTENT, "historical-overview.typ"), chomp: true, encoding: "UTF-8")
scan_lines = File.readlines(File.join(CONTENT, "scans.typ"), chomp: true, encoding: "UTF-8")

source_hashes = ACCEPTED_SOURCE_SHA256.to_h do |path, _expected|
  [path, Digest::SHA256.file(File.join(ROOT, path)).hexdigest]
end
front_typst = prose(front_lines[25..35], method(:typst_inline))
actual_headings = typst_headings(front_lines + historical_lines + scan_lines)
stable_headings = baseline_headings(SECTIONS)
typst_links = front_lines.filter_map { |line| line[/#link\("([^"]+)"\)/, 1] }

typst_ranges = scan_lines.join("\n").scan(/pdf-page-range\(\s*"\/scans\/nova_kronika_scans\.pdf",\s*(\d+),\s*(\d+)/m).map { |range| range.map(&:to_i) }
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
source_scan = File.join(ROOT, "scans/nova_kronika_scans.pdf")
source_scan_images = image_rows(run("pdfimages", "-list", source_scan))
embedded_scans = output_images[1, 36]
scan_signature = ->(row) { row.values_at("width", "height", "color", "components", "bits", "encoding") }
photo_dimensions = ACCEPTED_PHOTOS.map do |path|
  run("identify", "-format", "%w %h", File.join(ROOT, path)).split.map(&:to_i)
end
embedded_photo_dimensions = output_images.last(4).map { |row| row.values_at("width", "height") }

expected_media_pages = (4..6).to_a + (13..19).to_a + (21..50).to_a
ordinary_page = run("pdftotext", "-layout", "-f", "7", "-l", "7", PDF, "-")
media_text = expected_media_pages.flat_map do |page|
  run("pdftotext", "-f", page.to_s, "-l", page.to_s, PDF, "-").strip.empty? ? [] : [page]
end

checks = {
  "acceptedTypstSources" => source_hashes == ACCEPTED_SOURCE_SHA256,
  "frozenScanSource" => Digest::SHA256.file(source_scan).hexdigest == ACCEPTED_SCAN_SHA256,
  "titlePage" => front_lines.join("\n").include?("[Současná kronika]") && front_lines.join("\n").include?("subtitle: [TJ Sokol Poruba]") && front_lines.join("\n").include?('image-source: "/images/cover.jpg"') && front_lines.join("\n").include?("edition: [Digitální vydání]"),
  "frontMatterText" => Digest::SHA256.hexdigest(front_typst) == ACCEPTED_CREDIT_TYPST_SHA256,
  "creditSystemOnlyChange" => front_typst.scan(/\bTypst\b/).length == 1 && !front_typst.match?(/\bLaTeX\b/),
  "stableSectionInventory" => stable_headings == actual_headings,
  "externalLinks" => typst_links == ["https://github.com/vichr-vita/sokolska-kronika"],
  "intentionalLineBreak" => front_lines[34].end_with?("\\"),
  "scanRanges" => typst_ranges == ACCEPTED_SCAN_RANGES,
  "photoOrder" => typst_photos == ACCEPTED_PHOTOS,
  "qpdfClean" => qpdf_check.include?("No syntax or stream encoding errors found"),
  "typstVersion" => pdfinfo.include?("Creator:         Typst 0.15.1"),
  "documentMetadata" => pdfinfo.include?("Title:           Současná kronika") && pdfinfo.include?("Author:          TJ Sokol Poruba"),
  "czechLanguage" => catalog && catalog["/Lang"] == "u:cs",
  "a4Pages" => pdfinfo.include?("Page size:       595.276 x 841.89 pts (A4)"),
  "outlineOrder" => outline_titles == ["Obsah"] + stable_headings.map { |heading| heading["title"] },
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
  "creditComparison" => {
    "sourceSha256" => ACCEPTED_CREDIT_SOURCE_SHA256,
    "expectedTypstSha256" => ACCEPTED_CREDIT_TYPST_SHA256,
    "typstSha256" => Digest::SHA256.hexdigest(front_typst),
    "onlySystemNameChanged" => checks["creditSystemOnlyChange"] && checks["frontMatterText"],
  },
  "checks" => checks,
  "allPassed" => checks.values.all?,
}
File.write(REPORT, JSON.pretty_generate(report) + "\n", encoding: "UTF-8")
puts JSON.pretty_generate(report)
exit(report["allPassed"] ? 0 : 1)
