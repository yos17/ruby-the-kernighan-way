# log_summary.rb — count log entries per hour, broken down by level
# Usage: ruby log_summary.rb <logfile>

filename = ARGV[0]

# Walk every line, try to match our timestamp+level regex.
# `filter_map` keeps only the truthy results — lines that don't
# match return nil from `line.match` and get dropped automatically.
#
# Regex breakdown (try it on regex101.com):
#   ^(\d{4}-\d{2}-\d{2} \d{2})    → capture group 1: "YYYY-MM-DD HH"
#   :\d{2}:\d{2}                  → match :MM:SS (not captured)
#   \s+(\w+)                      → capture group 2: the log level
entries = File.foreach(filename)
              .filter_map { |line| line.match(/^(\d{4}-\d{2}-\d{2} \d{2}):\d{2}:\d{2}\s+(\w+)/) }

# `m[1]` pulls out capture group 1 (the hour prefix). `group_by`
# returns a hash: { "2026-04-17 09" => [matchdata, ...], ... }
by_hour = entries.group_by { |m| m[1] }

# Walk the hours in chronological order (hash sorts by key).
by_hour.sort.each do |hour, ms|
  # For every match in this hour, pluck capture group 2 (the
  # level) and count how many of each appear.
  level_counts = ms.map { |m| m[2] }.tally
  parts = level_counts.sort.map { |level, count| "#{level}=#{count}" }
  puts "#{hour}  #{parts.join(' ')}"
end
