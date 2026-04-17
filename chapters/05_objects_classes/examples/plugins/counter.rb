module Counter
  def tick
    @count ||= 0
    @count += 1
  end
end
