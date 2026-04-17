# Solution to Exercise 1
flags = { i: false, n: false, v: false, c: false, l: false }

while ARGV.first&.start_with?("-")
  arg = ARGV.shift
  arg[1..].each_char { |c| flags[c.to_sym] = true }
end

pattern_str = ARGV.shift
abort "usage: grep.rb [-i] [-n] [-v] [-c] [-l] PATTERN [FILE ...]" if pattern_str.nil?

pattern = Regexp.new(pattern_str, flags[:i] ? Regexp::IGNORECASE : 0)
sources = ARGV.map { |f| [f, File.open(f)] }

sources.each do |name, io|
  if flags[:l]
    found = io.each_line.any? { |line| pattern.match?(line) ^ flags[:v] }
    puts name if found
    next
  end

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
ensure
  io.close if io
end
