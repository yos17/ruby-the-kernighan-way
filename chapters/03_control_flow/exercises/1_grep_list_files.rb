# Exercise 1 — grep with -l flag
#
# Add a -l (list-files-only) option that prints just the filenames of files
# that have any matches, with no actual matched lines. Useful when piping
# results to xargs.
#
#   ruby exercises/1_grep_list_files.rb -l 'ERROR' examples/app.log examples/demo.txt
#   examples/app.log

flags = { i: false, n: false, v: false, c: false, l: false }

# TODO: parse flags including -l (the loop already handles unknown letters
#       since we just set the symbol)

while ARGV.first&.start_with?("-")
  arg = ARGV.shift
  arg[1..].each_char { |c| flags[c.to_sym] = true }
end

pattern_str = ARGV.shift
abort "usage: grep.rb [-i] [-n] [-v] [-c] [-l] PATTERN [FILE ...]" if pattern_str.nil?

pattern = Regexp.new(pattern_str, flags[:i] ? Regexp::IGNORECASE : 0)
sources = ARGV.map { |f| [f, File.open(f)] }

sources.each do |name, io|
  # TODO: when flags[:l] is true, print the filename if ANY line matches, then move to the next file
  # (don't print actual lines)

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
