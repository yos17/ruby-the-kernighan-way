if ARGV.empty?
  puts "Usage: echo.rb arg1 arg2 ..."
  exit 1 
end

ARGV.each_with_index do |arg, i|
  puts "#{i+ 1}:#{arg}"
end