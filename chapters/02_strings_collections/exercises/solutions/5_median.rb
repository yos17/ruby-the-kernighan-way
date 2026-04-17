# Solution to Exercise 5
filename = ARGV[0]
numbers = File.readlines(filename, chomp: true).map(&:to_f).sort

median = if numbers.length.odd?
           numbers[numbers.length / 2]
         else
           mid = numbers.length / 2
           (numbers[mid - 1] + numbers[mid]) / 2.0
         end

puts median
