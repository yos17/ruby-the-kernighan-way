# Exercise 4 — uptime.rb
#
# Find the longest run of consecutive minutes with no ERROR entries.
# Print the start and end timestamps of that quiet period.
#
# Approach:
#   1. Walk the log, collecting timestamps of all minutes where an ERROR occurred.
#   2. Compare against the full minute range from first to last log entry to find quiet runs.
#   OR (simpler):
#   1. For each minute in the log, mark it as ERROR or CLEAN.
#   2. Use chunk_while to group consecutive CLEAN minutes.
#   3. Pick the longest chunk.
#
# Usage: ruby exercises/4_uptime.rb examples/app.log

filename = ARGV[0]

# TODO: parse each line into [timestamp_to_minute, has_error?]
# TODO: take only minutes that are clean
# TODO: chunk_while into consecutive runs
# TODO: find the longest, print "<start>  <end>  (<n> minutes)"
