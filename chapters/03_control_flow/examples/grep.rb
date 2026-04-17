# grep.rb — find lines matching a regex pattern
# Usage: ruby grep.rb [-i] [-n] [-v] [-c] PATTERN [FILE ...]
#   -i  case-insensitive
#   -n  show line numbers
#   -v  invert (show non-matching lines)
#   -c  count only (print number of matches per file)

# All four flags default to off.
flags = { i: false, n: false, v: false, c: false }

# Parse flags from the front of ARGV. `&.start_with?` is the safe
# navigation operator: if ARGV is empty, `first` returns nil, and
# `nil&.start_with?("-")` is nil (falsy) instead of crashing.
while ARGV.first&.start_with?("-")
  arg = ARGV.shift
  # Support bundled flags like "-in" (== "-i -n"). `arg[1..]` is
  # everything from index 1 onwards, i.e. the flag letters without
  # the leading "-". We flip each letter's entry in the hash on.
  arg[1..].each_char { |c| flags[c.to_sym] = true }
end

pattern_str = ARGV.shift
abort "usage: grep.rb [-i] [-n] [-v] [-c] PATTERN [FILE ...]" if pattern_str.nil?

# Build the regex. The second argument to `Regexp.new` is a flag
# bitmask; 0 means no flags, IGNORECASE makes it case-insensitive.
pattern = Regexp.new(pattern_str, flags[:i] ? Regexp::IGNORECASE : 0)

# If no files were given, read from standard input (like real grep).
# Otherwise build a list of [name, open_file] pairs.
sources = ARGV.empty? ? [["(stdin)", STDIN]] : ARGV.map { |f| [f, File.open(f)] }

sources.each do |name, io|
  matches = 0
  # `with_index(1)` starts numbering from 1 (humans count from 1,
  # arrays from 0). Each iteration gives us (line, line_number).
  io.each_line.with_index(1) do |line, lineno|
    matched = pattern.match?(line)
    # XOR (^) is the classic "invert if -v is on" trick.
    # matched=true, v=false  => print.
    # matched=true, v=true   => skip (match, but inverted).
    # matched=false, v=true  => print (non-match, invert on).
    # matched=false, v=false => skip.
    next unless matched ^ flags[:v]
    matches += 1
    # In count-only mode we don't print lines, we just tally them.
    next if flags[:c]
    # Assemble an optional "filename:lineno:" prefix before the line.
    parts = []
    parts << name if sources.length > 1
    parts << lineno.to_s if flags[:n]
    print parts.empty? ? line : "#{parts.join(":")}:#{line}"
  end
  puts "#{name}:#{matches}" if flags[:c]
ensure
  # `ensure` always runs — even if the block above raised — so we
  # never leak file handles. Don't close STDIN; we didn't open it.
  io.close if io != STDIN
end
