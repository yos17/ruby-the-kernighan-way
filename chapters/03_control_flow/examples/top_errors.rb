# top_errors.rb — print the most common ERROR messages in a log
# Usage: ruby top_errors.rb [-n N] <logfile>

# Default to top 5, overridable with "-n N".
n = 5
if ARGV[0] == "-n"
  ARGV.shift
  n = ARGV.shift.to_i
end

filename = ARGV[0]

# `string[regex, group]` is a compact way to run a regex and pull
# out one capture group. Here:
#   \bERROR\b    → the word ERROR on word boundaries
#   \s+(.*)$     → grab everything after the whitespace (group 1)
# Non-matching lines return nil, which `filter_map` drops.
# `&.strip` trims whitespace only when we actually got a string.
errors = File.foreach(filename)
             .filter_map { |line| line[/\bERROR\b\s+(.*)$/, 1]&.strip }

# Tally the messages, sort most-frequent first (ties alphabetical),
# keep the top N, and print them as a right-aligned table.
errors.tally
      .sort_by { |msg, count| [-count, msg] }
      .first(n)
      .each { |msg, count| puts "#{count.to_s.rjust(4)}  #{msg}" }
