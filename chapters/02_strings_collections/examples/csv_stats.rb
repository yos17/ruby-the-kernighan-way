# csv_stats.rb — basic stats for numeric columns of a CSV
# Usage: ruby csv_stats.rb <file>

require "csv"

filename = ARGV[0]

# `headers: true` tells Ruby's CSV library to treat the first line
# as column names, so each row acts like a hash (row["price"]).
rows = CSV.read(filename, headers: true)

rows.headers.each do |column|
  # Collect every cell in this column as a string.
  values  = rows.map { |row| row[column] }

  # `filter_map` is like map + compact in one pass: run the block,
  # keep only the truthy results. `Float(v, exception: false)`
  # tries to parse the string — it returns `nil` (instead of
  # raising) on non-numeric cells, so those get silently dropped.
  numbers = values.filter_map { |v| Float(v, exception: false) }

  # Skip columns that had no numbers at all (e.g. a name column).
  next if numbers.empty?

  count = numbers.length
  sum   = numbers.sum
  mean  = sum / count
  min   = numbers.min
  max   = numbers.max

  puts "#{column}: count=#{count} sum=#{sum.round(2)} mean=#{mean.round(2)} min=#{min} max=#{max}"
end
