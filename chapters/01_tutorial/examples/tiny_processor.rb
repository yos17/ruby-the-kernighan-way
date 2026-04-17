# tiny_processor.rb — count lines, words, and characters in a file
# Usage: ruby tiny_processor.rb <filename>
#   ruby tiny_processor.rb notes.txt

# ARGV is an array of the command-line arguments the user typed
# after "ruby tiny_processor.rb". ARGV[0] is the first one.
filename = ARGV[0]

# Three running totals, all starting at zero.
lines = 0
words = 0
chars = 0

# `File.foreach` reads the file one line at a time. This is
# memory-friendly — it never loads the whole file at once, so it
# works fine for huge files too.
File.foreach(filename) do |line|
  lines += 1
  # `line.split` with no argument splits on runs of whitespace,
  # returning an array of "words". Its `.length` is the word count.
  words += line.split.length
  chars += line.length
end

puts "#{lines} lines, #{words} words, #{chars} characters"
