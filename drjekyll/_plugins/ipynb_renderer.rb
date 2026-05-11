require 'json'

module Jekyll
  module IpynbRenderer
    # Your custom language mapper
    def language_map_to_rouge(lang)
      return 'plaintext' if lang.nil?
      case lang.downcase
      when 'python' then 'python'
      when 'javascript' then 'javascript'
      when 'ruby' then 'ruby'
      when 'bash', 'sh', 'shell', 'shellscript' then 'bash'
      else 'plaintext'
      end
    end

    def render_ipynb(json_data, context)
      return "Error: No IPYNB data found." if json_data.nil?

      output = []
      data = json_data.is_a?(String) ? JSON.parse(json_data) : json_data

      data['cells'].each do |cell|
        source = Array(cell['source']).join("")

        if cell['cell_type'] == 'markdown'
          converter = context.registers[:site].find_converter_instance(Jekyll::Converters::Markdown)
          output << "<div class='ipynb-markdown'>#{converter.convert(source)}</div>"
        elsif cell['cell_type'] == 'code'
          # Use your helper method here
          raw_lang = cell.dig('metadata', 'vscode', 'languageId') ||
                     cell.dig('metadata', 'language_info', 'name')
          lang = language_map_to_rouge(raw_lang)

          highlighter = Jekyll::Tags::HighlightBlock.parse(
            'highlight',
            lang,
            Liquid::Tokenizer.new(source + "\n{% endhighlight %}"),
            Liquid::ParseContext.new
          )
          output << "<div class='ipynb-code'>#{highlighter.render(context)}</div>"
        end
      end
      output.join("\n")
    rescue JSON::ParserError => e
      "Error parsing IPYNB JSON: #{e.message}"
    end

    def read_ipynb_file(path, context)
      site = context.registers[:site]
      full_path = File.join(site.source, path.strip.gsub(/\A['"]|['"]\z/, ''))

      if File.exist?(full_path)
        JSON.parse(File.read(full_path))
      else
        "Error: File not found at #{full_path}"
      end
    end
  end

  class IpynbBlock < Liquid::Block
    include IpynbRenderer
    def initialize(tag_name, markup, tokens)
      super
      @file_path = markup.strip
    end

    def render(context)
      json = !@file_path.empty? ? read_ipynb_file(@file_path, context) : super.to_s.strip
      render_ipynb(json, context)
    end
  end

  class IpynbFileTag < Liquid::Tag
    include IpynbRenderer
    def initialize(tag_name, markup, tokens)
      super
      @file_path = markup.strip
    end

    def render(context)
      json = read_ipynb_file(@file_path, context)
      render_ipynb(json, context)
    end
  end
end

Liquid::Template.register_tag('ipynb', Jekyll::IpynbBlock)
Liquid::Template.register_tag('ipynb_file', Jekyll::IpynbFileTag)
