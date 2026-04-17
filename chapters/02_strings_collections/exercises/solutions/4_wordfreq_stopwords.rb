# Solution to Exercise 4
STOPWORDS = %w[the a an and or but in on at to of for with by from as is are was were be been]

n = 10
if ARGV[0] == "-n"
  ARGV.shift
  n = ARGV.shift.to_i
end

filename = ARGV[0]
text = File.read(filename).downcase

words = text.scan(/[a-z]+/).reject { |w| STOPWORDS.include?(w) }

frequencies = words.tally.sort_by { |word, count| [-count, word] }

frequencies.first(n).each do |word, count|
  puts "#{count.to_s.rjust(6)}  #{word}"
end
