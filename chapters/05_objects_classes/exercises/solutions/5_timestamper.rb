# Solution to Exercise 5
require "time"

module Timestamper
  def timestamp = Time.now.utc.iso8601
end

if __FILE__ == $PROGRAM_NAME
  obj = Object.new
  obj.extend(Timestamper)
  puts obj.timestamp
end
