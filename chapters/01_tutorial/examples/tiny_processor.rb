# tiny_processor.rb — count lines, words, and characters in a file
# Usage: ruby tiny_processor.rb <filename>
#   ruby tiny_processor.rb notes.txt

filename = ARGV[0]

lines = 0
words = 0
chars = 0

File.foreach(filename) do |line|
  lines += 1
  words += line.split.length
  chars += line.length
end

puts "#{lines} lines, #{words} words, #{chars} characters"
