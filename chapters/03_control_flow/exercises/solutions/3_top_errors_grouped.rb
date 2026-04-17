# Solution to Exercise 3
n = 5
if ARGV[0] == "-n"
  ARGV.shift
  n = ARGV.shift.to_i
end

filename = ARGV[0]

errors = File.foreach(filename)
             .filter_map { |line| line[/\bERROR\b\s+(.*)$/, 1]&.strip }

normalized = errors.map { |msg| msg.split(":").first.strip }

normalized.tally
          .sort_by { |msg, count| [-count, msg] }
          .first(n)
          .each { |msg, count| puts "#{count.to_s.rjust(4)}  #{msg}" }
