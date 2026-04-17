module Wordtools
  # Return the top N word/count pairs, sorting alphabetically for ties.
  # `n = 10` is a default argument — callers can omit the second
  # parameter and get the top 10. The `[-c, w]` key sorts by count
  # descending, then alphabetically — same trick used in wordfreq.rb.
  def self.top(text, n = 10)
    tally(text).sort_by { |w, c| [-c, w] }.first(n)
  end
end
