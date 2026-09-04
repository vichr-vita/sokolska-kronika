#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"

ROOT = File.expand_path("../..", __dir__)
SOURCE = File.join(ROOT, "stara_kronika.tex")
CONTENT = File.join(ROOT, "chronicles/predvalecna/content")

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

def inline(text)
  text = text.dup
  text.gsub!(/\\noindent(?![A-Za-z])/, "")
  text.gsub!(/\\\\\[([0-9.]+)(cm|em)\]\s*$/, "\\\n#v(\\1\\2)")
  text.gsub!(/\$1\\frac\{1\}\{2\}\$/, "1½")
  text.gsub!(/\$2\\frac\{1\}\{2\}\$/, "2½")
  text.gsub!(/\$\\frac\{1\}\{2\}\$/, "½")
  text.gsub!(/\$\\frac\{1\}\{4\}\$/, "¼")
  text.gsub!(/\$S_a\$/, "$S_a$")
  text.gsub!(/\\href\{([^{}]+)\}\{([^{}]+)\}/, '#link("\\1")[\\2]')

  replacements = {
    "textbf" => ["*", "*"],
    "emph" => ["_", "_"],
    "textit" => ["_", "_"],
    "enquote" => ["„", "“"],
  }
  loop do
    changed = false
    replacements.each do |command, delimiters|
      changed ||= !!text.gsub!(/\\#{command}\{([^{}]*)\}/) do
        "#{delimiters[0]}#{Regexp.last_match(1)}#{delimiters[1]}"
      end
    end
    break unless changed
  end

  text.gsub!(/\\textonehalf\{\}/, "½")
  text.gsub!(/\\textthreequarters\{\}/, "¾")
  text.gsub!(/\\checkmark\b/, "✓")
  text.gsub!(/\\dag\b/, "†")
  text.gsub!(/\\dots\b/, "…")
  text.gsub!(/\\LaTeX\b/, "LaTeX")
  text.gsub!(/\\,/, " ")
  text.gsub!(/\\%/, "%")
  text.gsub!(/\\(?=\s)/, "")
  text.gsub!(/\\hfill/, "#h(1fr)")
  text.gsub!(/\\dotfill/, "#h(1fr)")
  text.gsub!(/\\(?:bigskip|medskip)(?![A-Za-z])/, "")
  text.gsub!(/\\\[|\\\]/) { |value| value.delete("\\") }
  text.gsub!(/\\\\\s*(?:\[[^\]]+\])?\s*$/, "\\")
  text.strip
end

def table(lines, start_index)
  index = start_index + 1
  rows = []

  until lines[index]&.match?(/\\end\{tabular\}/)
    row = lines[index].strip
    index += 1
    next if row.empty? || row == "\\hline"

    row = row.sub(/\\\\\s*$/, "")
    rows << row.split(/\s*&\s*/, -1)
  end

  column_count = rows.map(&:length).max
  output = ["#table(", "  columns: #{column_count},", "  align: (#{(["left"] + ["right"] * (column_count - 1)).join(", ")}),", "  inset: 4pt,"]
  rows.each do |cells|
    rendered = cells.map do |cell|
      if (match = cell.match(/\\multicolumn\{(\d+)\}\{[^}]+\}\{(.*)\}/))
        "table.cell(colspan: #{match[1]}, align: center)[#{inline(match[2])}]"
      else
        "[#{inline(cell)}]"
      end
    end
    output << "  #{rendered.join(", ")},"
  end

  output << ")"
  [output, index]
end

def figure(lines, start_index)
  images = []
  caption = nil
  index = start_index + 1

  until lines[index]&.match?(/\\end\{figure\}/)
    line = lines[index]
    if (match = line.match(/\\adjustimage\{([^}]*)\}\{([^}]+)\}/))
      height = match[1].include?("0.3\\textheight") ? "70mm" : "210mm"
      images << "image(\"/#{match[2]}\", width: 100%, height: #{height}, fit: \"contain\")"
    elsif (match = line.match(/\\caption\{(.*)\}/))
      caption = inline(match[1])
    end
    index += 1
  end

  body = if images.length == 1
    images.first
  else
    "stack(dir: ttb, spacing: 3mm, #{images.join(", ")})"
  end
  output = ["#figure(", "  #{body},"]
  output << "  caption: [#{caption}]," if caption
  output << ")"
  [output, index]
end

def convert(lines)
  output = [
    '#import "../../shared/publication.typ": newspaper-clipping, verse',
    "",
  ]
  environments = []
  index = 0

  while index < lines.length
    raw = lines[index]
    stripped = raw.strip

    if stripped.empty? || stripped.start_with?("%")
      output << "" unless output.last == ""
    elsif stripped.match?(/\\(?:phantomsection|addcontentsline|markright|centering)\b/)
      # Navigation and centering are expressed by native Typst elements.
    elsif (match = stripped.match(/\\section\*?\{(.*)\}/))
      output << "= #{inline(match[1])}"
    elsif (match = stripped.match(/\\subsection\*?\{(.*)\}/))
      output << "== #{inline(match[1])}"
    elsif (match = stripped.match(/\\subsubsection\*\{(.*)\}/))
      output << "#heading(level: 3, outlined: false, bookmarked: false)[#{inline(match[1])}]"
    elsif stripped == "\\clearpage"
      output << "#pagebreak()"
    elsif stripped == "\\bigskip"
      output << "#v(1em)"
    elsif stripped == "\\medskip"
      output << "#v(0.5em)"
    elsif (match = stripped.match(/\\vspace\*?\{([0-9.]+)cm\}/))
      output << "#v(#{match[1]}cm)"
    elsif stripped.match?(/\\begin\{figure\}/)
      block, index = figure(lines, index)
      output.concat(block)
    elsif stripped.match?(/\\begin\{tabular\}/)
      block, index = table(lines, index)
      output.concat(block)
    elsif stripped == "\\begin{itemize}"
      environments << :itemize
    elsif stripped == "\\end{itemize}"
      environments.pop
    elsif stripped == "\\begin{enumerate}"
      environments << :enumerate
    elsif stripped == "\\end{enumerate}"
      environments.pop
    elsif stripped == "\\begin{description}"
      environments << :description
    elsif stripped == "\\end{description}"
      environments.pop
    elsif stripped == "\\begin{quote}"
      environments << :quote
      output << "#quote(block: true)["
    elsif stripped == "\\end{quote}"
      environments.pop
      output << "]"
    elsif stripped == "\\begin{verse}"
      environments << :verse
      output << "#verse["
    elsif stripped == "\\end{verse}"
      environments.pop
      output << "]"
    elsif stripped == "\\begin{novinovy-vystrizek}"
      environments << :clipping
      output << "#newspaper-clipping["
    elsif stripped == "\\end{novinovy-vystrizek}"
      environments.pop
      output << "]"
    elsif stripped == "\\begin{center}"
      environments << :center
      output << "#align(center)["
    elsif stripped == "\\end{center}"
      environments.pop
      output << "]"
    elsif stripped == "\\begin{flushright}"
      environments << :right
      output << "#align(right)["
    elsif stripped == "\\end{flushright}"
      environments.pop
      output << "]"
    elsif stripped.match?(/\\fbox\{\\begin\{minipage\}/)
      environments << :box
      output << "#block(width: 80%, inset: 12pt, stroke: 0.5pt)["
    elsif stripped.match?(/\\end\{minipage\}/)
      environments.pop
      output << "]"
    elsif stripped.start_with?("\\raggedleft \\footnotesize ")
      output << "#align(right, text(size: 8pt)[#{inline(stripped.sub('\\raggedleft \\footnotesize ', ''))}])"
    elsif (match = stripped.match(/\\item\[([^\]]+)\]\s*(.*)/))
      output << "/ *#{inline(match[1])}*: #{inline(match[2])}"
    elsif (match = stripped.match(/\\item\s+(.*)/))
      marker = environments.last == :enumerate ? "+" : "-"
      output << "#{marker} #{inline(match[1])}"
    else
      output << inline(raw)
    end

    index += 1
  end

  output.join("\n").gsub(/\n{3,}/, "\n\n").rstrip + "\n"
end

source_lines = File.readlines(SOURCE, chomp: true, encoding: "UTF-8")
output_dir = File.expand_path(ARGV.fetch(0, CONTENT))
FileUtils.mkdir_p(output_dir)

PERIODS.each do |filename, line_range|
  selected = source_lines[(line_range.begin - 1)..(line_range.end - 1)]
  File.write(File.join(output_dir, filename), convert(selected))
end
