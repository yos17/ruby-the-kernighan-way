# Exercise 5 — Timestamper plugin
#
# Write a Timestamper module with a single method `timestamp` that returns
# the current time as an ISO 8601 string (e.g., "2026-04-17T12:34:56Z").
# Save it as ../examples/plugins/timestamper.rb so the auto-loader picks it up.
#
# Hint: Time.now.utc.iso8601

module Timestamper
  # TODO: def timestamp
end

if __FILE__ == $PROGRAM_NAME
  # Pretend we're the Host
  obj = Object.new
  obj.extend(Timestamper)
  # puts obj.timestamp
end
