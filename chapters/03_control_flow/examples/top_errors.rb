# top_errors.rb — print the most common ERROR messages in a log
# Usage: ruby top_errors.rb [-n N] <logfile>

n = 5
if ARGV[0] == "-n"
  ARGV.shift
  n = ARGV.shift.to_i
end

filename = ARGV[0]

errors = File.foreach(filename)
             .filter_map { |line| line[/\bERROR\b\s+(.*)$/, 1]&.strip }

errors.tally
      .sort_by { |msg, count| [-count, msg] }
      .first(n)
      .each { |msg, count| puts "#{count.to_s.rjust(4)}  #{msg}" }
