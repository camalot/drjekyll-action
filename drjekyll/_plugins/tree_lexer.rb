# frozen_string_literal: true

begin
  require 'rouge' unless defined?(Rouge)
  require 'rouge/regex_lexer' unless defined?(Rouge::RegexLexer)
rescue LoadError
  # Jekyll may already load Rouge via its own dependency chain.
end

module Rouge
  module Lexers
    # Tree Lexer
    # Syntax highlighting for tree-style directory and hierarchy displays.
    # Recognises box-drawing / triangle characters (└ ├ │ ─ ▼ ▶), path
    # separators (/) and label terminators (:) as keywords, and inline
    # comments introduced by ← or <- (the two-char ASCII form is treated
    # identically to the Unicode arrow and styled as a comment).
    class Tree < Rouge::RegexLexer
      title 'Tree'
      desc 'Tree structure display'
      tag 'tree'
      aliases 'files', 'directory', 'dir'
      mimetypes 'text/x-tree'

      state :root do
        # Blank / whitespace-only lines
        rule %r{^\s*\n}, Text::Whitespace

        # Tree structure line: optional leading indent then one or more
        # box-drawing / triangle characters (└ ├ │ ─ ▼ ▶). The indent is
        # whitespace; the drawing characters are operators.
        rule %r{^([ \t]*)([└├│─▼▶]+)} do |m|
          token Text::Whitespace, m[1]
          token Operator, m[2]
          push :tree_content
        end

        # Tree command summary line: "N directories, N files" (or singular forms).
        # Emitted as a comment so it is visually de-emphasised.
        rule %r{^\d+ director(?:y|ies), \d+ files?\n?}, Comment::Single

        # Title / root-node line — no leading box-drawing prefix on this line.
        # Zero-width lookahead: confirmed non-empty so :title_content advances.
        rule %r{^(?=[^\n])} do
          push :title_content
        end

        rule %r{\n}, Text::Whitespace
      end

      # Content that follows tree box-drawing characters on a tree line.
      state :tree_content do
        # Additional box-drawing characters (multi-level connectors, e.g. │   └──)
        rule %r{[└├│─▼▶]+}, Operator

        # Inline comment: ← or <- with optional trailing whitespace.
        # Both forms are styled as Comment::Single; <- is NOT replaced in output.
        rule %r{(?:←|<-|\#)[ \t]*}, Comment::Single, :comment

        # Path / directory separator and label terminator
        rule %r{[/:]}, Keyword

        # Horizontal whitespace (indentation between connectors and names)
        rule %r{[ \t]+}, Text::Whitespace

        # End of line — pop back to :root
        rule %r{\n}, Text::Whitespace, :pop!

        # Symlink arrow emitted by the `tree` command: "name -> target".
        # The arrow is styled as an operator; the target is handled by :symlink_target.
        rule %r{->}, Operator, :symlink_target

        # Item labels, file names, task names.
        # Excludes box-drawing/triangle chars, slashes, colons, spaces/tabs,
        # and comment markers. The |<(?!-) alternative allows a lone <.
        rule %r{[^\n/:←<└├│─▼▶ \t]+|<(?!-)}, Name
      end

      # Title / root-node line content — rendered bold via Generic::Strong.
      state :title_content do
        # Inline comment: ← or <- or #
        rule %r{(?:←|<-|\#)[ \t]*}, Comment::Single, :comment

        # Path separator and label terminator
        rule %r{[/:]}, Keyword

        # Horizontal whitespace
        rule %r{[ \t]+}, Text::Whitespace

        # End of line — pop back to :root
        rule %r{\n}, Text::Whitespace, :pop!

        # Title text (bold). A lone < not followed by - is allowed in titles.
        rule %r{[^\n/:←< \t]+|<(?!-)}, Generic::Strong
      end

      # Symlink target following the -> arrow (tree command output).
      # Path separators are styled as keywords; everything else as a string.
      state :symlink_target do
        rule %r{[ \t]+}, Text::Whitespace
        rule %r{[/:]}, Keyword
        rule %r{[^\n/ \t:]+}, Str
        rule %r{\n}, Text::Whitespace, :pop!
      end

      # Comment text following ← or <- through end of line.
      state :comment do
        rule %r{[^\n]+}, Comment::Single
        rule %r{\n}, Text::Whitespace, :pop!
      end
    end
  end
end
