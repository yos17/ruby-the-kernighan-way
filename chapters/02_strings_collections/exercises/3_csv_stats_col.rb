# Exercise 3 — csv_stats with column selection
#
# Accept --col flags to limit which columns are reported.
# Examples:
#   ruby exercises/3_csv_stats_col.rb examples/sales.csv
#   ruby exercises/3_csv_stats_col.rb examples/sales.csv --col amount
#   ruby exercises/3_csv_stats_col.rb examples/sales.csv --col amount --col date
#
# When no --col flags are given, behave like the original csv_stats.rb (all numeric columns).

require "csv"

# TODO: walk ARGV, splitting it into:
#   - filename (the first non-flag argument)
#   - selected_columns (everything after each --col flag)
#
# Hint: ARGV.each_with_index lets you peek at neighboring arguments.

filename = nil
selected_columns = []
# TODO: parse ARGV here

rows = CSV.read(filename, headers: true)

columns_to_show = selected_columns.empty? ? rows.headers : selected_columns

columns_to_show.each do |column|
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
