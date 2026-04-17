module Counter
  # Increment and return a counter stored on the host object.
  def tick
    @count ||= 0
    @count += 1
  end
end
