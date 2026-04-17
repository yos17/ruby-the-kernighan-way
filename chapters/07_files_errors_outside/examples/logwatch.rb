# logwatch.rb — tail a file, alert when a pattern shows up
# Usage: ruby logwatch.rb <pattern> <file>
# Run in one terminal; from another: echo "ERROR something" >> file

require "set"

# Build a regex from the user-supplied pattern string. `if ARGV[0]`
# avoids crashing when the user forgets to pass anything.
pattern = Regexp.new(ARGV[0]) if ARGV[0]
filename = ARGV[1]
abort "usage: logwatch.rb PATTERN FILE" unless pattern && filename

# A Set is a collection with unique elements and O(1) lookup.
# Here we remember which line indexes we've already processed so
# we don't print old lines every time the loop iterates.
seen = Set.new

# `loop do ... end` is an infinite loop. The user stops it with Ctrl+C.
loop do
  break unless File.exist?(filename)
  File.foreach(filename).with_index do |line, i|
    # Skip lines we've processed on a previous iteration.
    next if seen.include?(i)
    seen << i
    if pattern.match?(line)
      # `line.chomp` strips the trailing newline so our output
      # doesn't have a blank line between entries.
      puts "[ALERT line #{i + 1}] #{line.chomp}"
    end
  end
  # Poll once a second. Real production tools use inotify or kqueue
  # instead, but `sleep`-based polling is simple and good enough
  # for small files.
  sleep 1
end
