module Wordtools
  # Return the top N word/count pairs, sorting alphabetically for ties.
  def self.top(text, n = 10)
    tally(text).sort_by { |w, c| [-c, w] }.first(n)
  end
end
