#!/usr/bin/env ruby
# textstats.rb — analyze text statistics
# Usage: ruby textstats.rb file.txt

if ARGV.empty?
  puts "Usage: textstats.rb file.txt"
  exit 1
end

text  = File.read(ARGV[0])
lines = text.lines.map(&:chomp)
words = text.split(/\s+/).reject(&:empty?)

word_freq = words
  .map(&:downcase)
  .map { |w| w.gsub(/[^a-z]/, "") }
  .reject(&:empty?)
  .tally
  .sort_by { |_, count| -count }

avg_word_len = words.sum(&:length).to_f / words.length

puts "=== Text Statistics ==="
puts "Lines:          #{lines.length}"
puts "Words:          #{words.length}"
puts "Characters:     #{text.length}"
puts "Unique words:   #{word_freq.length}"
puts "Avg word len:   #{avg_word_len.round(2)}"
puts ""
puts "=== Top 10 Words ==="
word_freq.first(10).each_with_index do |(word, count), i|
  bar = "█" * [count, 25].min
  puts "#{(i+1).to_s.rjust(2)}. #{word.ljust(15)} #{count.to_s.rjust(4)}  #{bar}"
end
