#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

ROOT = File.expand_path("../..", __dir__)
CONTENT = File.join(ROOT, "chronicles/predvalecna/content")
REPORT = File.join(__dir__, "pdf-verification.json")
PDF = File.expand_path(ARGV.fetch(0, "/tmp/opencode/predvalecna.pdf"))
CONTENT_FILES = %w[
  front-matter-body.typ
  1894-1900.typ
  1901-1905.typ
  1906-1910.typ
  1911-1915.typ
  1916-1920.typ
  1921-1925.typ
  1926-1930.typ
  1931-1934.typ
].freeze

def run(*command)
  stdout, stderr, status = Open3.capture3(*command)
  abort "#{command.join(' ')} failed:\n#{stderr}" unless status.success?
  stdout.force_encoding("UTF-8")
end

def flatten_outlines(items)
  items.flat_map { |item| [item] + flatten_outlines(item.fetch("kids", [])) }
end

def heading_title(text)
  text.gsub("~", " ").gsub(/[\u00a0\u202f]/, " ").gsub("---", "—").gsub("--", "–").delete("*_").strip
end

abort "missing or empty PDF: #{PDF}" unless File.file?(PDF) && File.size(PDF).positive?

qpdf_check = run("qpdf", "--check", PDF)
qpdf_json = run("qpdf", "--json", PDF).force_encoding("UTF-8")
pdf = JSON.parse(qpdf_json)
pdfinfo = run("pdfinfo", PDF)
page_count = pdf.fetch("pages").length
final_page = run("pdftotext", "-layout", "-f", page_count.to_s, "-l", page_count.to_s, PDF, "-").force_encoding("UTF-8")

expected_headings = CONTENT_FILES.flat_map do |filename|
  File.readlines(File.join(CONTENT, filename), encoding: "UTF-8", chomp: true).filter_map do |line|
    match = line.match(/^(={1,2})\s+(.*)$/)
    heading_title(match[2]) if match
  end
end
expected_outline_titles = ["Obsah"] + expected_headings
outlines = flatten_outlines(pdf.fetch("outlines"))
outline_titles = outlines.map { |item| item.fetch("title") }
outline_difference = [outline_titles.length, expected_outline_titles.length].min.times.find do |index|
  heading_title(outline_titles[index]) != expected_outline_titles[index]
end

objects = pdf.fetch("qpdf").fetch(1)
link_annotations = objects.values.count do |entry|
  value = entry["value"]
  value.is_a?(Hash) && value["/Subtype"] == "/Link"
end
catalog = objects.values.filter_map { |entry| entry["value"] if entry["value"].is_a?(Hash) }.find do |value|
  value["/Type"] == "/Catalog"
end

final_heading = expected_headings.last
checks = {
  "qpdfClean" => qpdf_check.include?("No syntax or stream encoding errors found"),
  "typstVersion" => pdfinfo.include?("Creator:         Typst 0.15.1"),
  "documentMetadata" => pdfinfo.include?("Title:           Předválečná kronika") && pdfinfo.include?("Author:          TJ Sokol Poruba"),
  "tagged" => pdfinfo.include?("Tagged:          yes"),
  "a4Pages" => pdfinfo.include?("Page size:       595.276 x 841.89 pts (A4)"),
  "czechLanguage" => catalog && catalog["/Lang"] == "u:cs",
  "outlineOrder" => outline_titles.map { |title| heading_title(title) } == expected_outline_titles,
  "contentsLinks" => link_annotations >= expected_outline_titles.length,
  "externalLink" => qpdf_json.include?("https://github.com/vichr-vita/sokolska-kronika"),
  "finalPage" => final_page.scan(final_heading).length >= 2 && final_page.include?("Zdena Janíček v.r.") && final_page.match?(/\b#{page_count}\s*\z/),
}

report = {
  "pdf" => File.basename(PDF),
  "bytes" => File.size(PDF),
  "pages" => page_count,
  "outlineEntries" => outlines.length,
  "topLevelBookmarks" => pdf.fetch("outlines").length,
  "linkAnnotations" => link_annotations,
  "firstBookmark" => outline_titles.first,
  "lastBookmark" => outline_titles.last,
  "firstOutlineDifference" => if outline_difference
    {
      "index" => outline_difference,
      "expected" => expected_outline_titles[outline_difference],
      "actual" => outline_titles[outline_difference],
    }
  end,
  "checks" => checks,
  "allPassed" => checks.values.all?,
}

File.write(REPORT, JSON.pretty_generate(report) + "\n", encoding: "UTF-8")
puts JSON.pretty_generate(report)
exit(report["allPassed"] ? 0 : 1)
