# Exercise 2 — logwatch with log rotation
#
# When the file shrinks (truncated, replaced by logrotate, etc.), reset state
# and re-scan from the start.
#
# Hint: track File.size between iterations. If size_now < size_then, reset.

require "set"

pattern  = Regexp.new(ARGV[0]) if ARGV[0]
filename = ARGV[1]
abort "usage: logwatch.rb PATTERN FILE" unless pattern && filename

seen = Set.new
last_size = 0

loop do
  break unless File.exist?(filename)
  size = File.size(filename)
  # TODO: detect rotation (size < last_size) and reset seen + last_size
  last_size = size

  File.foreach(filename).with_index do |line, i|
    next if seen.include?(i)
    seen << i
    puts "[ALERT line #{i + 1}] #{line.chomp}" if pattern.match?(line)
  end
  sleep 1
end
