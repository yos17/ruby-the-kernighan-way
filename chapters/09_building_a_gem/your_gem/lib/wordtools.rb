# Top-level entry point for the `wordtools` gem. When someone
# does `require "wordtools"`, this file runs and pulls in every
# piece of the library.
#
# `require_relative` loads a file whose path is relative to the
# current file — preferred over plain `require` inside a gem
# because it doesn't depend on the load path being set up right.
require_relative "wordtools/version"
require_relative "wordtools/tally"
require_relative "wordtools/top"

# Wordtools — the namespace module. Everything this gem exports
# lives inside it, so user code can't clash with our names.
module Wordtools
  # Gem-specific base error. Users can `rescue Wordtools::Error`
  # to catch anything this library might raise without accidentally
  # swallowing unrelated exceptions.
  class Error < StandardError; end
end
