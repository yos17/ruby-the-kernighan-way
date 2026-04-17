# log_summary.rb — count log entries per hour, broken down by level
# Usage: ruby log_summary.rb <logfile>

filename = ARGV[0]

entries = File.foreach(filename)
              .filter_map { |line| line.match(/^(\d{4}-\d{2}-\d{2} \d{2}):\d{2}:\d{2}\s+(\w+)/) }

by_hour = entries.group_by { |m| m[1] }

by_hour.sort.each do |hour, ms|
  level_counts = ms.map { |m| m[2] }.tally
  parts = level_counts.sort.map { |level, count| "#{level}=#{count}" }
  puts "#{hour}  #{parts.join(' ')}"
end
