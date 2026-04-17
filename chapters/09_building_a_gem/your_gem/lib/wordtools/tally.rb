module Wordtools
  # Count normalized words in the given text.
  def self.tally(text)
    text.downcase.scan(/[a-z]+/).tally
  end
end
