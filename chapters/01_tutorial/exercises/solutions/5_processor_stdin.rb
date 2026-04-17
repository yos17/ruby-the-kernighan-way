# Solution to Exercise 5
lines = 0
words = 0
chars = 0

count = ->(line) {
  lines += 1
  words += line.split.length
  chars += line.length
}

if ARGV.empty?
  STDIN.each_line(&count)
else
  ARGV.each do |filename|
    File.foreach(filename, &count)
  end
end

puts "#{lines} lines, #{words} words, #{chars} characters"
