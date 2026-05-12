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

    def self.process(content, css_class)
      lines      = content.lines
      result     = []
      in_fence   = false
      collecting = false
      yaml_lines = []
      # Treat start-of-content as preceded by a blank line so a --- at position
      # zero is a valid block opener without requiring a leading newline.
      prev_blank = true

      lines.each do |line|
        stripped = line.chomp

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

        if !collecting && stripped.match?(OPEN_PATTERN) && prev_blank
          collecting = true
          yaml_lines = []
          prev_blank = false
          next
        end

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
      values     = headers.map { |k| serialize_value(data[k]) }

      th_cells = headers.map { |h| "<th>#{CGI.escapeHTML(h.to_s)}</th>" }.join
      td_cells = values.map  { |v| "<td>#{CGI.escapeHTML(v)}</td>" }.join

      <<~HTML
        <div class="#{safe_class}">
          <table class="table table-bordered table-sm">
            <thead><tr>#{th_cells}</tr></thead>
            <tbody><tr>#{td_cells}</tr></tbody>
          </table>
        </div>
      HTML
    end

    def self.serialize_value(value)
      case value
      when Array    then value.map(&:to_s).join(', ')
      when Hash     then value.map { |k, v| "#{k}: #{v}" }.join("\n")
      when NilClass then ''
      else value.to_s
      end
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc|
  next if doc.content.nil?

  site_config = doc.site.config['embedded_frontmatter'] || {}
  next unless site_config.fetch('enabled', true)
  next if doc.data['render_embedded_frontmatter'] == false

  css_class   = site_config.fetch('css_class', 'frontmatter-table')
  doc.content = Jekyll::FrontmatterTable.process(doc.content, css_class)
end
