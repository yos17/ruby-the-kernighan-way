# csv_stats.rb — basic stats for numeric columns of a CSV
# Usage: ruby csv_stats.rb <file>

require "csv"

filename = ARGV[0]
rows = CSV.read(filename, headers: true)

rows.headers.each do |column|
  values  = rows.map { |row| row[column] }
  numbers = values.filter_map { |v| Float(v, exception: false) }
  next if numbers.empty?

  count = numbers.length
  sum   = numbers.sum
  mean  = sum / count
  min   = numbers.min
  max   = numbers.max

  puts "#{column}: count=#{count} sum=#{sum.round(2)} mean=#{mean.round(2)} min=#{min} max=#{max}"
end
