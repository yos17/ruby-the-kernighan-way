# Exercise 2 — grep with proper exit codes
#
# When matches are found in any file, exit 0 (success).
# When no matches are found in ANY file, exit 1 (failure).
# This makes grep usable in shell pipelines:
#   grep pattern file.log && echo "found it"
#
# Verify with:
#   ruby exercises/2_grep_exit_code.rb 'ERROR' examples/app.log; echo "exit=$?"
#   ruby exercises/2_grep_exit_code.rb 'NEVER_MATCHES' examples/app.log; echo "exit=$?"

flags = { i: false, n: false, v: false, c: false }

while ARGV.first&.start_with?("-")
  arg = ARGV.shift
  arg[1..].each_char { |c| flags[c.to_sym] = true }
end

pattern_str = ARGV.shift
abort "usage: grep.rb [-i] [-n] [-v] [-c] PATTERN [FILE ...]" if pattern_str.nil?

pattern = Regexp.new(pattern_str, flags[:i] ? Regexp::IGNORECASE : 0)
sources = ARGV.empty? ? [["(stdin)", STDIN]] : ARGV.map { |f| [f, File.open(f)] }

# TODO: track total matches across all files
# TODO: at the end, exit 1 if total matches == 0

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
ensure
  io.close if io != STDIN
end
