# Solution to Exercise 4
def with_retry(max: 3)
  attempts = 0
  delay = 0.5
  begin
    attempts += 1
    yield
  rescue StandardError
    raise if attempts >= max
    sleep(delay)
    delay *= 2
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
  puts result
  puts "calls: #{call_count}"
end
