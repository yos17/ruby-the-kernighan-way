# Counter — plugin module. When mixed into a Host, adds a `tick`
# method that remembers how many times it has been called.
module Counter
  # `@count ||= 0` is Ruby shorthand for "set @count to 0 if it's
  # currently nil or false". It's the usual way to lazily
  # initialize an instance variable on first use.
  def tick
    @count ||= 0
    @count += 1
  end
end
