# Exercise 3 — top_errors with prefix grouping
#
# Many error messages have variable parts (IPs, IDs, paths) that prevent
# tallying from working well. Group by the prefix before the first colon.
#
# Example log lines:
#   ERROR connection refused: 192.168.1.5
#   ERROR connection refused: 192.168.1.6
#   ERROR timeout reading socket fd=42
#
# Should count as:
#   2  connection refused
#   1  timeout reading socket fd=42

n = 5
if ARGV[0] == "-n"
  ARGV.shift
  n = ARGV.shift.to_i
end

filename = ARGV[0]

errors = File.foreach(filename)
             .filter_map { |line| line[/\bERROR\b\s+(.*)$/, 1]&.strip }

# TODO: normalize each error message — keep only what's before the first ":"
# (Hint: msg.split(":").first.strip)
normalized = errors  # TODO: replace this with the normalized version

normalized.tally
          .sort_by { |msg, count| [-count, msg] }
          .first(n)
          .each { |msg, count| puts "#{count.to_s.rjust(4)}  #{msg}" }
