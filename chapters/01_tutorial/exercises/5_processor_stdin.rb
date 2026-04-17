# Exercise 5 — tiny_processor.rb that reads stdin when no files given
#
# When ARGV is empty, read from STDIN instead of a file.
# Example:
#   cat notes.txt | ruby exercises/5_processor_stdin.rb
#   #=> 3 lines, 6 words, 34 characters
#
# When ARGV has filenames, behave like the original tiny_processor.rb.
#
# Hint: STDIN.each_line do |line| ... end iterates stdin lines.

lines = 0
words = 0
chars = 0

if ARGV.empty?
  # TODO: iterate STDIN.each_line, count lines/words/chars
else
  # TODO: iterate ARGV.each, opening each file with File.foreach
end

puts "#{lines} lines, #{words} words, #{chars} characters"
