#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "open3"
require "rbconfig"
require "tmpdir"

ROOT = File.expand_path("../..", __dir__)
LATEX = File.join(ROOT, "stara_kronika.tex")
LATEX_MAIN = File.join(ROOT, "stara_kronika_main.tex")
CONTENT = File.join(ROOT, "chronicles/predvalecna/content")
CONVERTER = File.join(__dir__, "convert.rb")
BASELINE = File.join(ROOT, "verification/latex-baseline/predvalecna-structured-blocks.txt")
MANIFEST = File.join(ROOT, "verification/latex-baseline/manifest.json")
PERIOD_REPORT = File.join(__dir__, "period-comparison.json")
REPORT = File.join(__dir__, "structured-comparison.json")

PERIODS = {
  "1894-1900.typ" => (92..396),
  "1901-1905.typ" => (402..869),
  "1906-1910.typ" => (875..1284),
  "1911-1915.typ" => (1290..1673),
  "1916-1920.typ" => (1679..2137),
  "1921-1925.typ" => (2143..2697),
  "1926-1930.typ" => (2703..3398),
  "1931-1934.typ" => (3404..3877),
}.freeze
LIST_ENVIRONMENTS = %w[itemize enumerate description].freeze
SPECIAL_ENVIRONMENTS = %w[tabular quote verse novinovy-vystrizek].freeze
TRACKED_ENVIRONMENTS = (LIST_ENVIRONMENTS + SPECIAL_ENVIRONMENTS).freeze

def selected_lines(lines)
  PERIODS.values.flat_map { |range| lines[(range.begin - 1)..(range.end - 1)] }
end

def source_inventory(lines)
  stack = []
  list_items = Hash.new(0)
  environments = []
  special_sequence = []
  plain_line_breaks = 0
  spaced_line_breaks = 0
  verse_line_counts = []
  current_verse_lines = nil

  lines.each do |line|
    stripped = line.strip
    if (match = stripped.match(/^\\begin\{([^}]+)\}/))
      environment = match[1]
      next unless TRACKED_ENVIRONMENTS.include?(environment)

      stack << environment
      environments << { "type" => environment, "nesting" => stack.join(">") }
      special_sequence << environment if SPECIAL_ENVIRONMENTS.include?(environment)
      current_verse_lines = 0 if environment == "verse"
      next
    end
    if (match = stripped.match(/^\\end\{([^}]+)\}/))
      environment = match[1]
      next unless TRACKED_ENVIRONMENTS.include?(environment)

      abort "unbalanced LaTeX environment #{environment}" unless stack.pop == environment
      if environment == "verse"
        verse_line_counts << current_verse_lines
        current_verse_lines = nil
      end
      next
    end

    list_items[stack.last] += 1 if stripped.start_with?("\\item") && LIST_ENVIRONMENTS.include?(stack.last)
    next if stack.include?("tabular")

    plain_line_breaks += 1 if stripped.match?(/\\\\\s*$/)
    spaced_line_breaks += 1 if stripped.match?(/\\\\\[[^\]]*\]\s*$/)
    current_verse_lines += 1 if current_verse_lines && !stripped.empty?
  end

  {
    "environmentSequence" => environments,
    "environmentCounts" => environments.map { |item| item["type"] }.tally,
    "specialSequence" => special_sequence,
    "listItemCounts" => list_items,
    "plainLineBreaksOutsideTables" => plain_line_breaks,
    "spacedLineBreaksOutsideTables" => spaced_line_breaks,
    "verseLineCounts" => verse_line_counts,
  }
end

def typst_inventory(lines)
  list_items = {
    "itemize" => lines.count { |line| line.match?(/^\s*-\s/) },
    "enumerate" => lines.count { |line| line.match?(/^\s*\+\s/) },
    "description" => lines.count { |line| line.match?(%r{^\s*/\s}) },
  }
  special_patterns = {
    "tabular" => /^#table\(/,
    "quote" => /^#quote\(block:\s*true\)\[/,
    "verse" => /^#verse\[/,
    "novinovy-vystrizek" => /^#newspaper-clipping\[/,
  }
  special_sequence = lines.filter_map do |line|
    special_patterns.find { |_name, pattern| line.match?(pattern) }&.first
  end

  verse_line_counts = []
  in_verse = false
  verse_lines = 0
  lines.each do |line|
    if line.match?(special_patterns.fetch("verse"))
      in_verse = true
      verse_lines = 0
    elsif in_verse && line.strip == "]"
      verse_line_counts << verse_lines
      in_verse = false
    elsif in_verse && !line.strip.empty? && !line.strip.start_with?("#v(")
      verse_lines += 1
    end
  end

  {
    "specialSequence" => special_sequence,
    "specialCounts" => special_sequence.tally,
    "listItemCounts" => list_items,
    "plainLineBreaksOutsideTables" => lines.count { |line| line.match?(/\\\s*$/) },
    "verseLineCounts" => verse_line_counts,
  }
end

def table_dimensions(lines)
  dimensions = []
  index = 0
  while index < lines.length
    unless lines[index].match?(/\\begin\{tabular\}/)
      index += 1
      next
    end

    rows = []
    index += 1
    until lines[index]&.match?(/\\end\{tabular\}/)
      row = lines[index].strip
      rows << row.sub(/\\\\\s*$/, "").split(/\s*&\s*/, -1) unless row.empty? || row == "\\hline"
      index += 1
    end
    dimensions << { "rows" => rows.length, "columns" => rows.map(&:length).max }
    index += 1
  end
  dimensions
end

def source_symbol_sequence(lines)
  converted = lines.join("\n")
  converted.gsub!(/\\checkmark\b/, "✓")
  converted.gsub!(/\\dag\b/, "†")
  converted.gsub!(/\\dots\b/, "…")
  converted.gsub!(/\$[12]?\\frac\{1\}\{2\}\$/, "½")
  converted.gsub!(/\$\\frac\{1\}\{4\}\$/, "¼")
  converted.gsub!(/\\textonehalf\{\}/, "½")
  converted.gsub!(/\\textthreequarters\{\}/, "¾")
  converted.scan(/[✓†…½¼¾]/)
end

def baseline_matches_sources
  files = {
    "stara_kronika.tex" => LATEX,
    "stara_kronika_main.tex" => LATEX_MAIN,
  }.transform_values { |path| File.readlines(path, chomp: true, encoding: "UTF-8") }

  records = File.readlines(BASELINE, chomp: true, encoding: "UTF-8").filter_map do |record|
    match = record.match(/\A([^:]+):(\d+):(.*)\z/)
    next unless match

    [match[1], match[2].to_i, match[3]]
  end
  mismatches = records.reject do |filename, line_number, expected|
    files.fetch(filename).fetch(line_number - 1) == expected
  end
  [records.length, mismatches]
end

manifest = JSON.parse(File.read(MANIFEST, encoding: "UTF-8"))
period_report = JSON.parse(File.read(PERIOD_REPORT, encoding: "UTF-8"))
source_lines = File.readlines(LATEX, chomp: true, encoding: "UTF-8")
period_source_lines = selected_lines(source_lines)
typst_lines = PERIODS.keys.flat_map do |filename|
  File.readlines(File.join(CONTENT, filename), chomp: true, encoding: "UTF-8")
end

generated_matches = {}
Dir.mktmpdir("sokolska-structure-") do |directory|
  _stdout, stderr, status = Open3.capture3(RbConfig.ruby, CONVERTER, directory)
  abort "source conversion failed:\n#{stderr}" unless status.success?

  PERIODS.each_key do |filename|
    generated_matches[filename] = File.binread(File.join(directory, filename)) == File.binread(File.join(CONTENT, filename))
  end
end

baseline_count, baseline_mismatches = baseline_matches_sources
source = source_inventory(period_source_lines)
typst = typst_inventory(typst_lines)
source_symbols = source_symbol_sequence(period_source_lines)
typst_symbols = typst_lines.join("\n").scan(/[✓†…½¼¾]/)
expected_hash = manifest.dig("predvalecna", "sourceSha256", "stara_kronika.tex")
actual_hash = Digest::SHA256.file(LATEX).hexdigest
checks = {
  "frozenSource" => actual_hash == expected_hash,
  "stableStructuredInventory" => baseline_mismatches.empty?,
  "fullGeneratedMarkup" => generated_matches.values.all?,
  "normalizedContent" => period_report.fetch("allPassed"),
  "structuredBlockOrder" => source["specialSequence"] == typst["specialSequence"],
  "structuredBlockCounts" => source["environmentCounts"].slice(*SPECIAL_ENVIRONMENTS) == typst["specialCounts"],
  "listItems" => source["listItemCounts"] == typst["listItemCounts"],
  "intentionalLineBreaks" => source["plainLineBreaksOutsideTables"] == typst["plainLineBreaksOutsideTables"],
  "verseLineation" => source["verseLineCounts"] == typst["verseLineCounts"],
  "symbols" => source_symbols == typst_symbols,
}

report = {
  "baselineSourceSha256" => actual_hash,
  "stableInventoryRecords" => baseline_count,
  "stableInventoryMismatches" => baseline_mismatches,
  "generatedMarkupMatches" => generated_matches,
  "sourceEnvironmentCounts" => source["environmentCounts"],
  "sourceEnvironmentNesting" => source["environmentSequence"].select { |item| item["nesting"].include?(">") },
  "tableDimensions" => table_dimensions(period_source_lines),
  "listItemCounts" => { "latex" => source["listItemCounts"], "typst" => typst["listItemCounts"] },
  "intentionalLineBreaksOutsideTables" => {
    "latexPlain" => source["plainLineBreaksOutsideTables"],
    "latexWithSpacing" => source["spacedLineBreaksOutsideTables"],
    "typstPlain" => typst["plainLineBreaksOutsideTables"],
  },
  "verseLineCounts" => { "latex" => source["verseLineCounts"], "typst" => typst["verseLineCounts"] },
  "symbolCounts" => { "latex" => source_symbols.tally, "typst" => typst_symbols.tally },
  "checks" => checks,
  "allPassed" => checks.values.all?,
}

File.write(REPORT, JSON.pretty_generate(report) + "\n", encoding: "UTF-8")
puts JSON.pretty_generate(report)
exit(report["allPassed"] ? 0 : 1)
