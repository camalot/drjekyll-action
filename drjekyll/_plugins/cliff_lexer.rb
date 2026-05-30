# frozen_string_literal: true

begin
  require 'rouge' unless defined?(Rouge)
  require 'rouge/regex_lexer' unless defined?(Rouge::RegexLexer)
rescue LoadError
  # Jekyll may already load Rouge via its own dependency chain.
end

module Rouge
  module Lexers
    # Cliff TOML Lexer
    # Syntax highlighting for cliff.toml configuration files (git-cliff).
    # Supports the full cliff-toml grammar including TOML structure, regex
    # fields, replacement fields, and embedded Tera templates in triple-quoted
    # string values.
    class CliffToml < Rouge::RegexLexer
      title 'Cliff TOML'
      desc 'Configuration syntax for git-cliff (cliff.toml)'
      tag 'cliff'
      aliases 'cliff-toml'
      filenames 'cliff.toml', '*.cliff.toml'
      mimetypes 'text/x-cliff-toml'

      TERA_KEYWORDS = %w[
        if elif else endif for endfor in break continue block endblock
        extends include import macro endmacro raw endraw set set_global
        filter endfilter as and or not is
      ].join('|').freeze

      TERA_FILTERS = %w[
        lower upper wordcount capitalize title replace reverse length trim
        trim_start trim_end trim_start_matches trim_end_matches truncate
        linebreaksbr striptags join sort unique slice first last nth filter
        map group_by concat split int float round abs date get default escape
        safe upper_first lower_first as_str json_encode urlencode
        urlencode_strict filesizeformat pluralize indent spaceless escape_xml
        trim_lines get_random
      ].join('|').freeze

      TERA_BUILTINS = 'range|now|throw|get_env'

      TERA_TESTS = %w[
        defined undefined string number iterable odd even divisibleby
        matching containing starting_with ending_with
      ].join('|').freeze

      state :root do
        # Line comments
        rule %r{#.*$}, Comment::Single

        # Section headers: [section] or [[section]]
        rule %r{^(\s*)(\[\[?)([^\]\n]+)(\]?\])(\s*)$} do |m|
          token Text::Whitespace, m[1]
          token Punctuation,      m[2]
          token Name::Label,      m[3]
          token Punctuation,      m[4]
          token Text::Whitespace, m[5]
        end

        # Tera template binding: any key = """...""" (checked before key-value)
        rule %r{([A-Za-z_][A-Za-z0-9_-]*)(\s*)(=)(\s*)(""")} do |m|
          token Name::Property,   m[1]
          token Text::Whitespace, m[2]
          token Punctuation,      m[3]
          token Text::Whitespace, m[4]
          token Punctuation,      m[5]
          push :tera_binding
        end

        # Regex-valued fields — double-quoted
        rule %r{\b(pattern|message|body|footer|tag_pattern)\b(\s*)(=)(\s*)(")} do |m|
          token Name::Property,   m[1]
          token Text::Whitespace, m[2]
          token Punctuation,      m[3]
          token Text::Whitespace, m[4]
          token Punctuation,      m[5]
          push :regex_double
        end

        # Regex-valued fields — single-quoted
        rule %r{\b(pattern|message|body|footer|tag_pattern)\b(\s*)(=)(\s*)(')} do |m|
          token Name::Property,   m[1]
          token Text::Whitespace, m[2]
          token Punctuation,      m[3]
          token Text::Whitespace, m[4]
          token Punctuation,      m[5]
          push :regex_single
        end

        # Replace/href fields — double-quoted
        rule %r{\b(replace|href)\b(\s*)(=)(\s*)(")} do |m|
          token Name::Property,   m[1]
          token Text::Whitespace, m[2]
          token Punctuation,      m[3]
          token Text::Whitespace, m[4]
          token Punctuation,      m[5]
          push :replace_double
        end

        # Replace/href fields — single-quoted
        rule %r{\b(replace|href)\b(\s*)(=)(\s*)(')} do |m|
          token Name::Property,   m[1]
          token Text::Whitespace, m[2]
          token Punctuation,      m[3]
          token Text::Whitespace, m[4]
          token Punctuation,      m[5]
          push :replace_single
        end

        # Generic key = value (must follow all specific key rules above)
        rule %r{([A-Za-z_][A-Za-z0-9_-]*)(\s*)(=)} do |m|
          token Name::Property,   m[1]
          token Text::Whitespace, m[2]
          token Punctuation,      m[3]
        end

        # Triple-quoted strings (single-quote variant; double-quote caught above)
        rule %r{'''}, Str, :triple_single

        # Single-line strings
        rule %r{"}, Str::Double, :string_double
        rule %r{'}, Str::Single, :string_single

        # Numbers
        rule %r{-?\d+\.\d+(?:[eE][+-]?\d+)?}, Num::Float
        rule %r{-?\d+(?:[eE][+-]?\d+)?},       Num::Integer

        # Booleans
        rule %r{\b(?:true|false)\b}, Keyword::Constant

        # Punctuation
        rule %r{[=,]},       Punctuation
        rule %r{[{}\[\]]},   Punctuation

        rule %r{\s+}, Text::Whitespace
      end

      # -----------------------------------------------------------------------
      # Tera template binding  key = """..."""
      # -----------------------------------------------------------------------
      state :tera_binding do
        rule %r{"""}, Punctuation, :pop!
        rule %r{\{#-?}, Comment::Multiline, :tera_comment
        rule %r{\{%-?}, Punctuation,        :tera_statement
        rule %r{\{\{-?}, Punctuation,       :tera_expression
        rule %r{\\.}, Str::Escape
        rule %r{[^{"\\]+|\{(?![{%#])}, Str
        rule %r{"}, Str
      end

      state :tera_comment do
        rule %r{-?#\}}, Comment::Multiline, :pop!
        rule %r{[^#]+|#(?!\})}, Comment::Multiline
      end

      state :tera_statement do
        rule %r{-?%\}}, Punctuation, :pop!
        mixin :tera_inside
      end

      state :tera_expression do
        rule %r{-?\}\}}, Punctuation, :pop!
        mixin :tera_inside
      end

      state :tera_inside do
        rule %r{\s+}, Text::Whitespace
        rule %r{\b(?:#{TERA_KEYWORDS})\b}, Keyword
        rule %r{\b(?:true|false)\b}, Keyword::Constant
        rule %r{\bself\b}, Name::Builtin
        rule %r{\b(?:#{TERA_FILTERS})\b}, Name::Function
        rule %r{\b(?:#{TERA_BUILTINS})\b}, Name::Builtin
        rule %r{\b(?:#{TERA_TESTS})\b}, Name::Function
        rule %r{"(?:[^"\\]|\\.)*"}, Str::Double
        rule %r{'(?:[^'\\]|\\.)*'}, Str::Single
        rule %r{\b\d+(?:\.\d+)?\b}, Num
        rule %r{\|}, Operator
        rule %r{==|!=|<=|>=|<|>|&&|\|\||[+\-*/%~]}, Operator
        rule %r{[A-Za-z_][A-Za-z0-9_]*}, Name::Variable
        rule %r{[(),.:\[\]=]}, Punctuation
      end

      # -----------------------------------------------------------------------
      # Regex-valued field string bodies
      # -----------------------------------------------------------------------
      state :regex_double do
        rule %r{"}, Punctuation, :pop!
        rule %r{\\.}, Str::Escape
        rule %r{[(){}|\^$.*+?\[\]]}, Keyword
        rule %r{[^"\\(){}|\^$.*+?\[\]]+}, Str::Regex
      end

      state :regex_single do
        rule %r{'}, Punctuation, :pop!
        rule %r{\\.}, Str::Escape
        rule %r{[(){}|\^$.*+?\[\]]}, Keyword
        rule %r{[^'\\(){}|\^$.*+?\[\]]+}, Str::Regex
      end

      # -----------------------------------------------------------------------
      # Replace/href field string bodies
      # -----------------------------------------------------------------------
      state :replace_double do
        rule %r{"}, Punctuation, :pop!
        rule %r{\\.}, Str::Escape
        rule %r{\$\{\d+\}}, Name::Variable
        rule %r{\$\d+},     Name::Variable
        rule %r{[^"\\$]+},  Str
      end

      state :replace_single do
        rule %r{'}, Punctuation, :pop!
        rule %r{\\.}, Str::Escape
        rule %r{\$\{\d+\}}, Name::Variable
        rule %r{\$\d+},     Name::Variable
        rule %r{[^'\\$]+},  Str
      end

      # -----------------------------------------------------------------------
      # Triple-quoted string (''' variant)
      # -----------------------------------------------------------------------
      state :triple_single do
        rule %r{'''}, Str, :pop!
        rule %r{\\.}, Str::Escape
        rule %r{[^'\\]+|'(?!'')}, Str
      end

      # -----------------------------------------------------------------------
      # Single-line strings
      # -----------------------------------------------------------------------
      state :string_double do
        rule %r{"}, Str::Double, :pop!
        rule %r{\\.}, Str::Escape
        rule %r{[^"\\]+}, Str::Double
      end

      state :string_single do
        rule %r{'}, Str::Single, :pop!
        rule %r{[^']+}, Str::Single
      end
    end
  end
end
