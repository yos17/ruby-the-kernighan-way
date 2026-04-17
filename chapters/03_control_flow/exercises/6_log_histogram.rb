# Exercise 6 — log_histogram.rb
#
# Print a horizontal bar chart of total log entries per hour, scaled so the
# longest bar is at most 30 chars.
#
# Example output:
#   2026-04-17 10  ####### 7
#
# Usage: ruby exercises/6_log_histogram.rb examples/app.log

MAX_WIDTH = 30

filename = ARGV[0]

entries = File.foreach(filename)
              .filter_map { |line| line.match(/^(\d{4}-\d{2}-\d{2} \d{2}):\d{2}:\d{2}/) }

by_hour = entries.group_by { |m| m[1] }
counts  = by_hour.transform_values(&:length)

# TODO: compute scale (max_count > MAX_WIDTH ? max_count / MAX_WIDTH.to_f : 1.0)
# TODO: iterate counts.sort, print "<hour>  <bar> <count>"
