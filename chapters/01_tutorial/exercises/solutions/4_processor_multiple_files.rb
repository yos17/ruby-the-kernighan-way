# Solution to Exercise 4
total_lines = 0
total_words = 0
total_chars = 0

ARGV.each do |filename|
  lines = 0
  words = 0
  chars = 0

  File.foreach(filename) do |line|
    lines += 1
    words += line.split.length
    chars += line.length
  end

  puts "#{filename}: #{lines} lines, #{words} words, #{chars} characters"

  total_lines += lines
  total_words += words
  total_chars += chars
end

puts "total: #{total_lines} lines, #{total_words} words, #{total_chars} characters"
