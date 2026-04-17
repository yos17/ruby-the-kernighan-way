# flex.rb — flexible attribute object via method_missing
# Usage: ruby flex.rb (demo)

class Flex
  # Copy the starting data so this object owns its own hash.
  def initialize(data = {}) = @data = data.dup

  # Return a shallow copy of the backing hash.
  def to_h = @data.dup

  # Read one value using hash-style access.
  def [](key) = @data[key]

  # Write one value using hash-style access.
  def []=(key, value)
    @data[key] = value
  end

  # Turn method calls like config.host and config.port= into hash access.
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

  # Keep Ruby's introspection honest for the dynamic methods above.
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
