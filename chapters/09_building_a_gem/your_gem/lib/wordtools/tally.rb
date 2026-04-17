module Wordtools
  def self.tally(text)
    text.downcase.scan(/[a-z]+/).tally
  end
end
