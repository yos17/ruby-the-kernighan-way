# Solution to Exercise 6
MAX_WIDTH = 30

filename = ARGV[0]

entries = File.foreach(filename)
              .filter_map { |line| line.match(/^(\d{4}-\d{2}-\d{2} \d{2}):\d{2}:\d{2}/) }

counts = entries.group_by { |m| m[1] }.transform_values(&:length)

max = counts.values.max
scale = max > MAX_WIDTH ? max.to_f / MAX_WIDTH : 1.0

counts.sort.each do |hour, count|
  bar = "#" * (count / scale).ceil
  puts "#{hour}  #{bar} #{count}"
end
