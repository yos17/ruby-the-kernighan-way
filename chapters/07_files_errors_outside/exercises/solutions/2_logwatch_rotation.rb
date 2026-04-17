# Solution to Exercise 2
require "set"

pattern  = Regexp.new(ARGV[0]) if ARGV[0]
filename = ARGV[1]
abort "usage: logwatch.rb PATTERN FILE" unless pattern && filename

seen = Set.new
last_size = 0

loop do
  break unless File.exist?(filename)
  size = File.size(filename)

  if size < last_size
    warn "[logwatch] file shrunk; resetting"
    seen.clear
  end
  last_size = size

  File.foreach(filename).with_index do |line, i|
    next if seen.include?(i)
    seen << i
    puts "[ALERT line #{i + 1}] #{line.chomp}" if pattern.match?(line)
  end
  sleep 1
end
