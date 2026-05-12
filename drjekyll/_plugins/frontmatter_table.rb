# frozen_string_literal: true

require 'yaml'
require 'cgi'

module Jekyll
  module FrontmatterTable
    # Matches the opening --- of a potential YAML block (nothing else on the line)
    OPEN_PATTERN  = /\A---\s*\z/
    # Matches the closing --- (allows trailing spaces/tabs, not newlines)
    CLOSE_PATTERN = /\A---[ \t]*\z/
    # Matches the opening of a fenced code block (``` or ~~~, 3+ chars)
    FENCE_PATTERN = /\A(`{3,}|~{3,})/

    # A YAML key starts a word character, optional word/hyphen chars, then colon.
    YAML_KEY_PATTERN = /\A\w[\w-]*:/

    def self.process(content, css_class)
      lines        = content.lines
      result       = []
      in_fence     = false
      in_highlight = false
      collecting   = false
      yaml_lines   = []
      # Treat start-of-content as preceded by a blank line so a --- at position
      # zero is a valid block opener without requiring a leading newline.
      prev_blank   = true

      lines.each_with_index do |line, idx|
        stripped = line.chomp

        # ── Liquid {% highlight %} / {% endhighlight %} blocks ─────────────
        # Check opening only when not already inside a fence or highlight block.
        if !in_fence && !in_highlight && !collecting &&
           stripped.match?(/\A\{%-?\s*highlight\b/)
          in_highlight = true
          result << line
          prev_blank = false
          next
        end

        if in_highlight
          in_highlight = false if stripped.match?(/\A\{%-?\s*endhighlight\b/)
          result << line
          next
        end

        # ── Markdown fenced code blocks ─────────────────────────────────────
        if !collecting && stripped.match?(FENCE_PATTERN)
          in_fence = !in_fence
          result << line
          prev_blank = false
          next
        end

        if in_fence
          result << line
          next
        end

        # ── YAML block opening ──────────────────────────────────────────────
        if !collecting && stripped.match?(OPEN_PATTERN) && prev_blank
          # Lookahead: only collect if the very next line looks like a YAML key.
          # This distinguishes embedded frontmatter from a markdown horizontal
          # rule (--- preceded and followed by blank lines or headings).
          next_stripped = lines[idx + 1]&.chomp || ''
          if next_stripped.match?(YAML_KEY_PATTERN)
            collecting = true
            yaml_lines = []
            prev_blank = false
            next
          end
        end

        # ── YAML block body / close ─────────────────────────────────────────
        if collecting
          if stripped.match?(CLOSE_PATTERN)
            yaml_str = yaml_lines.join
            begin
              data = YAML.safe_load(yaml_str, permitted_classes: [Date, Time, Symbol])
              if data.is_a?(Hash) && !data.empty?
                result << "\n\n#{generate_table(data, css_class)}\n\n"
              else
                result << "---\n"
                result.concat(yaml_lines)
                result << line
              end
            rescue Psych::SyntaxError, Psych::DisallowedClass
              result << "---\n"
              result.concat(yaml_lines)
              result << line
            end
            collecting = false
            yaml_lines = []
          else
            yaml_lines << line
          end
          prev_blank = stripped.empty?
          next
        end

        result << line
        prev_blank = stripped.empty?
      end

      # Unclosed block — restore unchanged
      if collecting
        result << "---\n"
        result.concat(yaml_lines)
      end

      result.join
    end

    def self.generate_table(data, css_class)
      safe_class = CGI.escapeHTML(css_class.to_s)
      headers    = data.keys

      th_cells = headers.map { |h| "<th>#{CGI.escapeHTML(h.to_s)}</th>" }.join
      td_cells = headers.map { |k| "<td>#{serialize_value_html(data[k])}</td>" }.join

      <<~HTML
        <div class="#{safe_class}">
          <table class="table table-bordered table-sm">
            <thead><tr>#{th_cells}</tr></thead>
            <tbody><tr>#{td_cells}</tr></tbody>
          </table>
        </div>
      HTML
    end

    def self.serialize_value_html(value)
      case value
      when Array
        return '' if value.empty?
        if value.all? { |v| v.is_a?(Hash) }
          render_nested_table(value)
        else
          value.map { |v| "<div>#{CGI.escapeHTML(v.to_s)}</div>" }.join
        end
      when Hash
        return '' if value.empty?
        value.map { |k, v| "#{CGI.escapeHTML(k.to_s)}: #{CGI.escapeHTML(v.to_s)}" }.join('<br>')
      when NilClass
        ''
      when Integer, Float
        "<code>#{CGI.escapeHTML(value.to_s)}</code>"
      when TrueClass, FalseClass
        "<code>#{value}</code>"
      else
        str = CGI.escapeHTML(value.to_s)
        # Catch quoted YAML booleans ("true", "false") delivered as strings
        str.match?(/\A(true|false)\z/i) ? "<code>#{str}</code>" : str
      end
    end

    def self.render_nested_table(array_of_hashes)
      all_keys = array_of_hashes.flat_map(&:keys).uniq
      th_cells = all_keys.map { |k| "<th>#{CGI.escapeHTML(k.to_s)}</th>" }.join
      tr_rows  = array_of_hashes.map do |obj|
        cells = all_keys.map { |k| "<td>#{serialize_value_html(obj.fetch(k, nil))}</td>" }.join
        "<tr>#{cells}</tr>"
      end.join
      "<table class=\"table table-bordered table-sm mb-0\"><thead><tr>#{th_cells}</tr></thead><tbody>#{tr_rows}</tbody></table>"
    end
  end

  # Runs during Jekyll's generation phase — after all files are read but before
  # any Liquid or Kramdown rendering starts. This is intentionally a Generator
  # rather than a :pre_render hook; in Jekyll 4 the hook fires inside do_layout
  # after render_liquid has already run, so raw YAML blocks would reach Kramdown
  # unmodified and render as <hr> + prose.
  class FrontmatterTableGenerator < Generator
    safe true

    def generate(site)
      config    = site.config['embedded_frontmatter'] || {}
      return unless config.fetch('enabled', true)

      css_class = config.fetch('css_class', 'frontmatter-table')

      (site.pages + site.documents).each do |doc|
        next if doc.content.nil?
        next if doc.data['render_embedded_frontmatter'] == false

        doc.content = FrontmatterTable.process(doc.content, css_class)
      end
    end
  end
end
