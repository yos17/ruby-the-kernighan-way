# Solution to Exercise 2
flags = { i: false, n: false, v: false, c: false }

while ARGV.first&.start_with?("-")
  arg = ARGV.shift
  arg[1..].each_char { |c| flags[c.to_sym] = true }
end

pattern_str = ARGV.shift
abort "usage: grep.rb [-i] [-n] [-v] [-c] PATTERN [FILE ...]" if pattern_str.nil?

pattern = Regexp.new(pattern_str, flags[:i] ? Regexp::IGNORECASE : 0)
sources = ARGV.empty? ? [["(stdin)", STDIN]] : ARGV.map { |f| [f, File.open(f)] }

total_matches = 0

sources.each do |name, io|
  matches = 0
  io.each_line.with_index(1) do |line, lineno|
    matched = pattern.match?(line)
    next unless matched ^ flags[:v]
    matches += 1
    next if flags[:c]
    parts = []
    parts << name if sources.length > 1
    parts << lineno.to_s if flags[:n]
    print parts.empty? ? line : "#{parts.join(":")}:#{line}"
  end
  puts "#{name}:#{matches}" if flags[:c]
  total_matches += matches
ensure
  io.close if io && io != STDIN
end

exit 1 if total_matches.zero?
