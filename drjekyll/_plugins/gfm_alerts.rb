# frozen_string_literal: true

module Jekyll
  # Converts GitHub-flavored alert blockquotes (`> [!NOTE]`) into DrJekyll
  # callout blockquotes styled by assets/css/_callouts.scss.
  #
  # This runs on rendered HTML instead of markdown source so that alerts coming
  # from `_includes` (which are only expanded during Liquid rendering) are
  # converted as well.
  module GfmAlerts
    PATTERN = %r{
      <blockquote(?<bq_attrs>[^>]*)>\s*<p(?<p_attrs>[^>]*)>\s*
      \[!(?<type>NOTE|TIP|IMPORTANT|WARNING|CAUTION)\][^\S\n]*[^\n<]*\n?\s*
    }xi

    def self.process(html)
      return html unless html.is_a?(String) && html.include?('[!')

      html.gsub(PATTERN) do
        match = Regexp.last_match
        "<blockquote#{merge_class(match[:bq_attrs], match[:type].downcase)}><p#{match[:p_attrs]}>"
      end
    end

    def self.merge_class(attrs, type)
      attrs = attrs.to_s
      return "#{attrs} class=\"#{type}\"" unless attrs =~ /\sclass\s*=\s*(["'])(.*?)\1/

      attrs.sub(/(\sclass\s*=\s*)(["'])(.*?)\2/) { "#{Regexp.last_match(1)}\"#{Regexp.last_match(3)} #{type}\"" }
    end
  end

  Jekyll::Hooks.register :site, :post_render do |site|
    (site.pages + site.documents).each do |doc|
      next unless doc.output.is_a?(String)

      doc.output = GfmAlerts.process(doc.output)
    end
  end
end
