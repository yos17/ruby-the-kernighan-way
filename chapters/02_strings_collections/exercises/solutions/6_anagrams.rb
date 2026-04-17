# Solution to Exercise 6
filename = ARGV[0]
words = File.readlines(filename, chomp: true)

groups = words.group_by { |w| w.chars.sort.join }

groups.each_value do |group|
  puts group.join(", ")
end
