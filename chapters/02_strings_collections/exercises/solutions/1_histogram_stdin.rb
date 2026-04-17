# Solution to Exercise 1
lines = ARGV.empty? ? STDIN.readlines(chomp: true) : File.readlines(ARGV[0], chomp: true)
counts = lines.tally

counts.sort_by { |_value, count| -count }.each do |value, count|
  bar = "#" * count
  puts "#{value.ljust(15)} #{bar} #{count}"
end
