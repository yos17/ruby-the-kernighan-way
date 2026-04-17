# Exercise 4 — wordfreq with a stopword list
#
# Skip common words ("the", "and", "in", "of", ...) when counting.
# Define the stopword list as a constant at the top of the file.

STOPWORDS = %w[the a an and or but in on at to of for with by from as is are was were be been]

n = 10
if ARGV[0] == "-n"
  ARGV.shift
  n = ARGV.shift.to_i
end

filename = ARGV[0]
text = File.read(filename).downcase

words = text.scan(/[a-z]+/)

# TODO: filter out words that are in STOPWORDS

frequencies = words.tally.sort_by { |_word, count| -count }

frequencies.first(n).each do |word, count|
  puts "#{count.to_s.rjust(6)}  #{word}"
end
