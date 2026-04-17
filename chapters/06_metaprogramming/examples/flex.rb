# flex.rb — flexible attribute object via method_missing
# Usage: ruby flex.rb (demo)

# Flex — a "dynamic attribute" object. You can read and write any
# attribute you like without declaring it in advance:
#   config = Flex.new; config.port = 8080; config.port  # => 8080
#
# This works thanks to `method_missing`, Ruby's "what to do when
# someone calls a method that doesn't exist" hook.
class Flex
  # Copy the starting data so this object owns its own hash.
  # `.dup` makes a shallow copy — if the caller mutates the hash
  # they passed in, we don't see it.
  def initialize(data = {}) = @data = data.dup

  # Return a shallow copy of the backing hash.
  def to_h = @data.dup

  # Read one value using hash-style access.
  def [](key) = @data[key]

  # Write one value using hash-style access.
  def []=(key, value)
    @data[key] = value
  end

  # `method_missing` is called by Ruby when you invoke a method
  # that this object doesn't actually define. The `name` argument
  # is the method symbol; `args` are whatever was passed.
  #
  # Here we intercept two patterns:
  #   *  `obj.foo = value`  → Ruby calls `:foo=` on us → save value
  #   *  `obj.foo`          → Ruby calls `:foo`       → return value
  #
  # `super` at the bottom re-raises the default NoMethodError for
  # anything we don't recognise — always important, otherwise typos
  # silently return nil and you debug for hours.
  def method_missing(name, *args)
    name_str = name.to_s
    if name_str.end_with?("=")
      @data[name_str.chomp("=").to_sym] = args.first
    elsif @data.key?(name)
      @data[name]
    else
      super
    end
  end

  # Whenever you override `method_missing` you should *also* override
  # `respond_to_missing?` so `obj.respond_to?(:host)` returns true
  # for your dynamic methods. Otherwise Ruby's introspection tools
  # (like `method`, `respond_to?`, doctests) will lie about what
  # this object can do.
  def respond_to_missing?(name, include_private = false)
    @data.key?(name) || name.to_s.end_with?("=") || super
  end
end

if __FILE__ == $PROGRAM_NAME
  config = Flex.new(host: "localhost")
  config.port = 8080
  config.ssl  = true

  puts config.host
  puts config.port
  puts config.ssl
  puts config.respond_to?(:host)
  puts config.respond_to?(:nope)
end
