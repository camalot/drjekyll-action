# frozen_string_literal: true

begin
  require 'rouge' unless defined?(Rouge)
  require 'rouge/regex_lexer' unless defined?(Rouge::RegexLexer)
rescue LoadError
  # Jekyll may already load Rouge via its own dependency chain.
end

module Rouge
  module Lexers
    # Tera Lexer
    # Syntax highlighting for Tera template files.
    # Highlights {# #} comments, {% %} statements, and {{ }} expression blocks;
    # everything outside those delimiters is emitted as plain text.
    class Tera < Rouge::RegexLexer
      title 'Tera'
      desc 'Tera template language'
      tag 'tera'
      filenames '*.tera', '*.html.tera', '*.md.tera', '*.txt.tera'
      mimetypes 'text/x-tera'

      KEYWORDS = %w[
        if elif else endif for endfor in break continue block endblock
        extends include import macro endmacro raw endraw set set_global
        filter endfilter as and or not is
      ].join('|').freeze

      FILTERS = %w[
        lower upper wordcount capitalize title replace reverse length trim
        trim_start trim_end trim_start_matches trim_end_matches truncate
        linebreaksbr striptags join sort unique slice first last nth filter
        map group_by concat split int float round abs date get default escape
        safe upper_first lower_first as_str json_encode urlencode
        urlencode_strict filesizeformat pluralize indent spaceless escape_xml
        trim_lines get_random
      ].join('|').freeze

      BUILTINS = 'range|now|throw|get_env'

      TESTS = %w[
        defined undefined string number iterable odd even divisibleby
        matching containing starting_with ending_with
      ].join('|').freeze

      state :root do
        rule %r{\{#-?}, Comment::Multiline, :tera_comment
        rule %r{\{%-?}, Punctuation, :tera_statement
        rule %r{\{\{-?}, Punctuation, :tera_expression
        rule %r{[^{]+|\{(?![{%#])}, Text
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
        rule %r{\b(?:#{KEYWORDS})\b}, Keyword
        rule %r{\b(?:true|false)\b}, Keyword::Constant
        rule %r{\bself\b}, Name::Builtin
        rule %r{\b(?:#{FILTERS})\b}, Name::Function
        rule %r{\b(?:#{BUILTINS})\b}, Name::Builtin
        rule %r{\b(?:#{TESTS})\b}, Name::Function
        rule %r{"(?:[^"\\]|\\.)*"}, Str::Double
        rule %r{'(?:[^'\\]|\\.)*'}, Str::Single
        rule %r{\b\d+(?:\.\d+)?\b}, Num
        rule %r{\|}, Operator
        rule %r{==|!=|<=|>=|<|>|&&|\|\||[+\-*/%~]}, Operator
        rule %r{[A-Za-z_][A-Za-z0-9_]*}, Name::Variable
        rule %r{[(),.:\[\]=]}, Punctuation
      end
    end
  end
end
