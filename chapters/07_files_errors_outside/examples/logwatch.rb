# logwatch.rb — tail a file, alert when a pattern shows up
# Usage: ruby logwatch.rb <pattern> <file>
# Run in one terminal; from another: echo "ERROR something" >> file

require "set"

pattern = Regexp.new(ARGV[0]) if ARGV[0]
filename = ARGV[1]
abort "usage: logwatch.rb PATTERN FILE" unless pattern && filename

seen = Set.new
loop do
  break unless File.exist?(filename)
  File.foreach(filename).with_index do |line, i|
    next if seen.include?(i)
    seen << i
    if pattern.match?(line)
      puts "[ALERT line #{i + 1}] #{line.chomp}"
    end
  end
  sleep 1
end
