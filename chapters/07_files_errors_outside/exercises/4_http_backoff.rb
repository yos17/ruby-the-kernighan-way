# Exercise 4 — with_retry with exponential backoff
#
# Wait 0.5, 1.0, 2.0 seconds between retries (doubling each time).
# After max attempts, re-raise.

def with_retry(max: 3)
  attempts = 0
  delay = 0.5
  begin
    attempts += 1
    yield
  rescue StandardError
    raise if attempts >= max
    # TODO: sleep(delay), then double delay
    retry
  end
end

if __FILE__ == $PROGRAM_NAME
  call_count = 0
  result = with_retry do
    call_count += 1
    raise "boom" if call_count < 3
    "ok"
  end
  puts result      # "ok" after ~1.5s of cumulative sleep
  puts call_count  # 3
end
