# wordfreq.rb — print the N most-frequent words in a text
# Usage: ruby wordfreq.rb [-n N] <file>

# Tiny argument parser: if the user passed "-n 20", peel both
# pieces off the front of ARGV and use 20 as our top-N value.
n = 10
if ARGV[0] == "-n"
  ARGV.shift            # drop "-n"
  n = ARGV.shift.to_i   # consume and convert the number
end

filename = ARGV[0]

# Downcase so "The" and "the" count as the same word.
text = File.read(filename).downcase

# `scan` returns every substring matching the pattern.
# /[a-z]+/ = "one or more lowercase letters in a row" — that's our
# definition of a word. Punctuation and spaces drop out automatically.
words = text.scan(/[a-z]+/)

# Two-level sort trick: Ruby compares arrays element by element,
# so sorting by [-count, word] means "most frequent first, then
# alphabetical for ties". The minus flips the direction.
frequencies = words.tally.sort_by { |word, count| [-count, word] }

# `rjust(6)` right-aligns the number in a 6-character column so
# the output lines up like a neat table.
frequencies.first(n).each do |word, count|
  puts "#{count.to_s.rjust(6)}  #{word}"
end
