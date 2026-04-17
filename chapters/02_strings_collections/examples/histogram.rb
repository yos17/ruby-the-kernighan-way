# histogram.rb — print a horizontal bar chart of value frequencies
# Usage: ruby histogram.rb <file>

filename = ARGV[0]
counts = File.readlines(filename, chomp: true).tally

counts.sort_by { |_value, count| -count }.each do |value, count|
  bar = "#" * count
  puts "#{value.ljust(15)} #{bar} #{count}"
end
