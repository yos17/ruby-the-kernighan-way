# wordfreq.rb — print the N most-frequent words in a text
# Usage: ruby wordfreq.rb [-n N] <file>

n = 10
if ARGV[0] == "-n"
  ARGV.shift
  n = ARGV.shift.to_i
end

filename = ARGV[0]
text = File.read(filename).downcase

words = text.scan(/[a-z]+/)

frequencies = words.tally.sort_by { |word, count| [-count, word] }

frequencies.first(n).each do |word, count|
  puts "#{count.to_s.rjust(6)}  #{word}"
end
