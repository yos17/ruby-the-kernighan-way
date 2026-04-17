# Solution to Exercise 2
class Counter
  def initialize
    @counts = Hash.new(0)
  end

  def method_missing(name, *args)
    name_str = name.to_s
    if name_str.end_with?("!")
      key = name_str.chomp("!").to_sym
      @counts[key] += 1
    else
      @counts[name]
    end
  end

  def respond_to_missing?(name, include_private = false) = true
end

if __FILE__ == $PROGRAM_NAME
  c = Counter.new
  puts c.signups        # 0
  puts c.signups!       # 1
  puts c.signups!       # 2
  puts c.failures       # 0
  puts c.failures!      # 1
end
