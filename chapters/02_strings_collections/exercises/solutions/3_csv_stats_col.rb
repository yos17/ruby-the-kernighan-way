# Solution to Exercise 3
require "csv"

filename = nil
selected_columns = []
i = 0
while i < ARGV.length
  case ARGV[i]
  when "--col"
    selected_columns << ARGV[i + 1]
    i += 2
  else
    filename = ARGV[i]
    i += 1
  end
end

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
