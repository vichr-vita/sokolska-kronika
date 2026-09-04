#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"

ROOT = File.expand_path("../..", __dir__)
LATEX = File.join(ROOT, "stara_kronika.tex")
LATEX_MAIN = File.join(ROOT, "stara_kronika_main.tex")
CONTENT = File.join(ROOT, "chronicles/predvalecna/content")
MANIFEST = File.join(ROOT, "verification/latex-baseline/manifest.json")
SECTIONS = File.join(ROOT, "verification/latex-baseline/predvalecna-sections.txt")
REPORT = File.join(__dir__, "period-comparison.json")

PERIODS = {
  "1894-1900" => (92..396),
  "1901-1905" => (402..869),
  "1906-1910" => (875..1284),
  "1911-1915" => (1290..1673),
  "1916-1920" => (1679..2137),
  "1921-1925" => (2143..2697),
  "1926-1930" => (2703..3398),
  "1931-1934" => (3404..3877),
}.freeze

def normalize(text)
  text
    .unicode_normalize(:nfc)
    .gsub("~", " ")
    .gsub(/[\u00a0\u202f\u2060]/, " ")
    .gsub("---", "—")
    .gsub("--", "–")
    .gsub(/[„“”"]/, "")
    .gsub(/(\d)½/, '\\1 1/2')
    .gsub(/(\d)¾/, '\\1 3/4')
    .gsub("½", "1/2")
    .gsub("¼", "1/4")
    .gsub("¾", "3/4")
    .gsub(/[[:space:]]+/, " ")
    .strip
end

def latex_inline(text)
  value = text.dup
  value.gsub!(/\\noindent(?![A-Za-z])/, "")
  value.gsub!(/\\href\{([^{}]+)\}\{([^{}]+)\}/, "\\2")
  value.gsub!(/\$1\\frac\{1\}\{2\}\$/, "1 1/2")
  value.gsub!(/\$2\\frac\{1\}\{2\}\$/, "2 1/2")
  value.gsub!(/\$\\frac\{1\}\{2\}\$/, "1/2")
  value.gsub!(/\$\\frac\{1\}\{4\}\$/, "1/4")
  value.gsub!(/\$S_a\$/, "Sa")
  value.gsub!(/\\href\{[^{}]+\}\{([^{}]+)\}/, "\\1")
  loop do
    before = value.dup
    value.gsub!(/\\(?:textbf|emph|textit|enquote)\{([^{}]*)\}/, "\\1")
    value.gsub!(/\\multicolumn\{\d+\}\{[^{}]+\}\{([^{}]*)\}/, "\\1")
    break if value == before
  end
  value.gsub!(/(\d)\\textonehalf\{\}/, '\\1 1/2')
  value.gsub!(/(\d)\\textthreequarters\{\}/, '\\1 3/4')
  value.gsub!(/\\textonehalf\{\}/, "1/2")
  value.gsub!(/\\textthreequarters\{\}/, "3/4")
  value.gsub!(/\\checkmark\b/, "✓")
  value.gsub!(/\\dag\b/, "†")
  value.gsub!(/\\dots\b/, "…")
  value.gsub!(/\\LaTeX\b/, "LaTeX")
  value.gsub!(/\\(?:hfill|dotfill|bigskip|medskip|centering|raggedleft|footnotesize)(?![A-Za-z])/, " ")
  value.gsub!(/\\(?:section|subsection|subsubsection)\*?\{([^{}]*)\}/, "\\1")
  value.gsub!(/\\item\[([^\]]+)\]/, "\\1 ")
  value.gsub!(/\\item\b/, " ")
  value.gsub!(/\\(?:vspace\*?|hspace)\{[^{}]*\}/, " ")
  value.gsub!(/\\(?:phantomsection|clearpage|hline)\b/, " ")
  value.gsub!(/\\(?:addcontentsline|markright)\{[^{}]*\}\{[^{}]*\}(?:\{[^{}]*\})?/, " ")
  value.gsub!(/\\(?:begin|end)\{[^{}]*\}(?:\[[^\]]*\])?/, " ")
  value.gsub!(/\\adjustimage\{[^{}]*\}\{[^{}]*\}/, " ")
  value.gsub!(/\\caption\{([^{}]*)\}/, "\\1")
  value.gsub!(/\\fbox\{|\\begin\{minipage\}\{[^{}]*\}/, " ")
  value.gsub!(/\\,/, " ")
  value.gsub!(/\\%/, "%")
  value.gsub!(/\\(?=\s)/, "")
  value.gsub!(/\\\\(?:\[[^\]]*\])?/, " ")
  value.gsub!(/[{}$&]/, " ")
  normalize(value)
end

def latex_text(lines)
  normalize(lines.filter_map do |line|
    stripped = line.strip
    next if stripped.empty? || stripped.start_with?("%")
    next if stripped.match?(/\\(?:phantomsection|clearpage|bigskip|medskip|centering|hline)\s*$/)
    next if stripped.match?(/\\(?:addcontentsline|markright)/)
    next if stripped.match?(/\\(?:begin|end)\{(?:figure|tabular|itemize|enumerate|description|quote|verse|novinovy-vystrizek|center|flushright)\}/)
    next if stripped.match?(/\\adjustimage/)
    next if stripped.match?(/\\fbox\{\\begin\{minipage\}/)

    latex_inline(stripped)
  end.join(" "))
end

def typst_text(lines)
  normalize(lines.filter_map do |line|
    stripped = line.strip
    next if stripped.empty? || stripped.start_with?("#import")
    next if stripped.match?(/^#(?:pagebreak|v|figure|image|stack|quote|verse|newspaper-clipping|table|block|align)\b/) && !stripped.match?(/^#align\([^\]]+\)\[[^\]]+\]/)
    next if stripped == "stack("
    next if stripped.include?('image("/')
    next if ["]", ")", "),", "],"].include?(stripped)
    next if stripped.match?(/^(?:columns|align|inset|dir|spacing|image)\s*:/)

    value = stripped.sub(/^={1,3}\s+/, "")
    value.sub!(/^[-+]\s+/, "")
    value.sub!(/^\/\s+\*([^*]+)\*:\s*/, "\\1 ")
    value.gsub!(/#link\("[^"]+"\)\[([^\]]*)\]/, "\\1")
    value.gsub!(/#raw\("([^"]*)"\)/, "\\1")
    value.gsub!(/#sym\.at/, "@")
    if value.start_with?("table.cell")
      value = value.scan(/(?:table\.cell\([^)]*\))?\[([^\]]*)\]/).flatten.join(" ")
    end
    value.gsub!(/\$S_a\$/, "Sa")
    value.gsub!(/#heading\([^\]]*\)\[([^\]]*)\]/, "\\1")
    value.gsub!(/#h\([^)]*\)/, "")
    value.gsub!(/#align\([^\]]*text\([^\]]*\)\[([^\]]*)\]\)/, "\\1")
    value.gsub!(/#(?:align|text)\([^\]]*\)\[([^\]]*)\]/, "\\1")
    value.gsub!(/table\.cell\([^\]]*\)\[([^\]]*)\]/, "\\1")
    value.gsub!(/^caption:\s*\[(.*)\],$/, "\\1")
    table_row = value.include?(", [") || value.start_with?("[")
    value = value.scan(/\[([^\]]*)\]/).flatten.join(" ") if table_row
    value.gsub!(/[*_]/, "")
    value.gsub!(/\\$/, " ")
    normalize(value)
  end.join(" "))
end

def latex_headings(lines)
  lines.filter_map do |line|
    match = line.match(/\\(section|subsection)\*?\{(.*)\}/)
    next unless match

    { "level" => match[1] == "section" ? 1 : 2, "text" => normalize(latex_inline(match[2])) }
  end
end

def typst_headings(lines)
  lines.filter_map do |line|
    match = line.match(/^(={1,2})\s+(.*)$/)
    next unless match

    { "level" => match[1].length, "text" => normalize(match[2]) }
  end
end

def latex_emphasis(lines)
  lines.flat_map do |line|
    line.scan(/\\(textbf|emph|textit)\{([^{}]*)\}/).map do |command, text|
      { "style" => command == "textbf" ? "strong" : "emphasis", "text" => latex_inline(text) }
    end
  end
end

def typst_emphasis(lines)
  pattern = /\*([^*]+)\*|(?<![[:alnum:]\/])_([^_]+)_(?![[:alnum:]])|#text\(style: "italic"\)\[#raw\("([^"]*)"\)\]|#text\(style: "italic"\)\[me#sym\.at#h\(0pt\)vichr\.me\]/
  lines.flat_map do |line|
    line.to_enum(:scan, pattern).map do
      match = Regexp.last_match
      if match[1]
        { "style" => "strong", "text" => normalize(match[1]) }
      else
        text = match[2] || match[3] || "me@vichr.me"
        { "style" => "emphasis", "text" => normalize(text) }
      end
    end
  end
end

def baseline_headings(path)
  File.readlines(path, chomp: true, encoding: "UTF-8").filter_map do |line|
    match = line.match(/\A\\contentsline \{(section|subsection)\}\{(.*)\}\{\d+\}\{section\*\.\d+\}%\z/)
    next unless match

    { "level" => match[1] == "section" ? 1 : 2, "text" => normalize(latex_inline(match[2])) }
  end
end

manifest = JSON.parse(File.read(MANIFEST, encoding: "UTF-8"))
expected_source_hash = manifest.dig("predvalecna", "sourceSha256", "stara_kronika.tex")
actual_source_hash = Digest::SHA256.file(LATEX).hexdigest
abort "LaTeX source differs from frozen baseline" unless actual_source_hash == expected_source_hash
expected_main_hash = manifest.dig("predvalecna", "sourceSha256", "stara_kronika_main.tex")
actual_main_hash = Digest::SHA256.file(LATEX_MAIN).hexdigest
abort "LaTeX entry point differs from frozen baseline" unless actual_main_hash == expected_main_hash

source_lines = File.readlines(LATEX, chomp: true, encoding: "UTF-8")
main_lines = File.readlines(LATEX_MAIN, chomp: true, encoding: "UTF-8")
front_lines = File.readlines(File.join(CONTENT, "front-matter.typ"), chomp: true, encoding: "UTF-8")
front_body_lines = File.readlines(File.join(CONTENT, "front-matter-body.typ"), chomp: true, encoding: "UTF-8")
front_source_lines = main_lines[115..142] + source_lines[7..83]
front_source_media_lines = main_lines[93..142] + source_lines[7..83]
front_source_text = latex_text(front_source_lines)
front_typst_text = typst_text(front_body_lines)
front_source_media = front_source_media_lines.filter_map { |line| line[/\\adjustimage\{[^}]*\}\{([^}]+)\}/, 1] }
front_typst_media = (front_lines + front_body_lines).filter_map do |line|
  line[/image(?:-source:\s*|\()"\/([^\"]+)"/, 1]
end
front_source_links = front_source_lines.filter_map { |line| line[/\\href\{([^}]+)\}/, 1] }
front_typst_links = front_body_lines.filter_map { |line| line[/#link\("([^"]+)"\)/, 1] }
front_source_headings = latex_headings(front_source_lines)
front_typst_headings = typst_headings(front_body_lines)
front_source_emphasis = latex_emphasis(front_source_lines)
front_typst_emphasis = typst_emphasis(front_body_lines)
front_source_title = [
  main_lines[97][/sokolred\}\s*([^}]*)/, 1],
  main_lines[98][/bfseries\s+([^}]*)/, 1],
  main_lines[100][/large\s+([^}]*)/, 1],
]
front_typst_title = [front_lines[9][/\[(.*)\]/, 1], front_lines[10][/\[(.*)\]/, 1], front_lines[12][/\[(.*)\]/, 1]]
front_result = {
  "titlePage" => { "values" => front_source_title, "match" => front_source_title == front_typst_title },
  "headings" => { "count" => front_source_headings.length, "match" => front_source_headings == front_typst_headings },
  "media" => { "references" => front_source_media, "match" => front_source_media == front_typst_media },
  "links" => { "targets" => front_source_links, "match" => front_source_links == front_typst_links },
  "emphasis" => {
    "count" => front_source_emphasis.length,
    "match" => front_source_emphasis == front_typst_emphasis,
  },
  "normalizedText" => {
    "sourceSha256" => Digest::SHA256.hexdigest(front_source_text),
    "typstSha256" => Digest::SHA256.hexdigest(front_typst_text),
    "match" => front_source_text == front_typst_text,
  },
}
unless front_source_text == front_typst_text
  source_words = front_source_text.split
  typst_words = front_typst_text.split
  difference = [source_words.length, typst_words.length].min.times.find { |i| source_words[i] != typst_words[i] }
  difference ||= [source_words.length, typst_words.length].min
  front_result["firstTextDifference"] = {
    "word" => difference,
    "sourceWordCount" => source_words.length,
    "typstWordCount" => typst_words.length,
    "source" => source_words[[difference - 5, 0].max, 11]&.join(" "),
    "typst" => typst_words[[difference - 5, 0].max, 11]&.join(" "),
  }
end

results = PERIODS.map do |name, line_range|
  latex_lines = source_lines[(line_range.begin - 1)..(line_range.end - 1)]
  typst_path = File.join(CONTENT, "#{name}.typ")
  abort "missing #{typst_path}" unless File.file?(typst_path)

  typst_lines = File.readlines(typst_path, chomp: true, encoding: "UTF-8")
  source_headings = latex_headings(latex_lines)
  migrated_headings = typst_headings(typst_lines)
  source_media = latex_lines.filter_map { |line| line[/\\adjustimage\{[^}]*\}\{([^}]+)\}/, 1] }
  migrated_media = typst_lines.filter_map { |line| line[/image\("\/([^\"]+)"/, 1] }
  source_text = latex_text(latex_lines)
  migrated_text = typst_text(typst_lines)

  result = {
    "period" => name,
    "sourceLines" => "#{line_range.begin}-#{line_range.end}",
    "headings" => {
      "count" => source_headings.length,
      "match" => source_headings == migrated_headings,
    },
    "media" => {
      "references" => source_media,
      "match" => source_media == migrated_media,
    },
    "normalizedText" => {
      "sourceSha256" => Digest::SHA256.hexdigest(source_text),
      "typstSha256" => Digest::SHA256.hexdigest(migrated_text),
      "match" => source_text == migrated_text,
    },
  }
  unless result["headings"]["match"] && result["media"]["match"] && result["normalizedText"]["match"]
    unless source_text == migrated_text
      source_words = source_text.split
      typst_words = migrated_text.split
      difference = [source_words.length, typst_words.length].min.times.find { |i| source_words[i] != typst_words[i] }
      difference ||= [source_words.length, typst_words.length].min
      source_chars = source_text.each_char.to_a
      typst_chars = migrated_text.each_char.to_a
      char_difference = [source_chars.length, typst_chars.length].min.times.find { |i| source_chars[i] != typst_chars[i] }
      char_difference ||= [source_chars.length, typst_chars.length].min
      result["firstTextDifference"] = {
        "word" => difference,
        "character" => char_difference,
        "sourceCodepoint" => source_chars[char_difference]&.ord,
        "typstCodepoint" => typst_chars[char_difference]&.ord,
        "sourceCharacters" => source_chars[[char_difference - 30, 0].max, 70]&.join,
        "typstCharacters" => typst_chars[[char_difference - 30, 0].max, 70]&.join,
        "sourceWordCount" => source_words.length,
        "typstWordCount" => typst_words.length,
        "source" => source_words[[difference - 4, 0].max, 9]&.join(" "),
        "typst" => typst_words[[difference - 4, 0].max, 9]&.join(" "),
      }
    end
  end
  result
end

all_typst_headings = typst_headings(front_body_lines) + PERIODS.keys.flat_map do |name|
  typst_headings(File.readlines(File.join(CONTENT, "#{name}.typ"), chomp: true, encoding: "UTF-8"))
end
stable_headings = baseline_headings(SECTIONS)
front_source_line_breaks = front_source_lines.count { |line| line.match?(/\\\\(?:\[[^\]]*\])?\s*$/) }
front_typst_line_breaks = front_body_lines.count { |line| line.match?(/\\\s*$/) }

report = {
  "baselineSourceSha256" => actual_source_hash,
  "baselineEntryPointSha256" => actual_main_hash,
  "baselineSourceMatchesManifest" => true,
  "stableSectionInventory" => {
    "count" => stable_headings.length,
    "match" => stable_headings == all_typst_headings,
  },
  "frontMatter" => front_result,
  "frontMatterIntentionalLineBreaks" => {
    "source" => front_source_line_breaks,
    "typst" => front_typst_line_breaks,
    "match" => front_source_line_breaks == front_typst_line_breaks,
  },
  "periods" => results,
  "allPassed" => stable_headings == all_typst_headings &&
    front_result.values.all? { |check| check["match"] } &&
    front_source_line_breaks == front_typst_line_breaks && results.all? do |result|
    result["headings"]["match"] && result["media"]["match"] && result["normalizedText"]["match"]
  end,
}
File.write(REPORT, JSON.pretty_generate(report) + "\n", encoding: "UTF-8")
puts JSON.pretty_generate(report)
exit(report["allPassed"] ? 0 : 1)
