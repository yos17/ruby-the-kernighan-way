# Solution to Exercise 4
require "time"

filename = ARGV[0]

entries = File.foreach(filename)
              .filter_map { |line| line.match(/^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}):\d{2}\s+(\w+)/) }

minutes = entries.map { |m| [m[1], m[2] == "ERROR"] }

# Mark each unique minute as clean (no ERROR) or dirty (any ERROR)
status = minutes.group_by(&:first).transform_values { |pairs| pairs.none? { |_, err| err } }
sorted = status.sort_by { |minute, _| minute }

# chunk consecutive minutes by their clean/dirty status, then keep clean runs
clean_runs = sorted.chunk { |_, clean| clean }
                   .select { |clean, _| clean }
                   .map    { |_, group| group.map(&:first) }

if clean_runs.empty?
  puts "no clean periods"
else
  longest = clean_runs.max_by(&:length)
  puts "#{longest.first}  #{longest.last}  (#{longest.length} minutes clean)"
end
