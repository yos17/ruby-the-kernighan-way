module Wordtools
  # Count normalized words in the given text.
  # `self.tally` defines a method on the module itself, so callers
  # write `Wordtools.tally("...")` instead of having to create an
  # instance. This is the idiomatic shape for stateless utilities.
  def self.tally(text)
    # `downcase` folds case so "The" == "the". `scan(/[a-z]+/)`
    # pulls out every run of lowercase letters, dropping punctuation
    # and whitespace. Then `.tally` counts occurrences.
    text.downcase.scan(/[a-z]+/).tally
  end
end
