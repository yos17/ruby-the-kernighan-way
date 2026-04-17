# events.rb — a minimal pub/sub event bus
# Usage: ruby events.rb (demo)

# EventBus — a publish/subscribe hub. Objects register handlers
# for named topics with `on`, and `emit` fans an event out to
# every handler that cares about that topic.
class EventBus
  # `Hash.new { |h, k| h[k] = [] }` creates a hash whose default
  # value for a missing key is a fresh empty array — and, crucially,
  # it stores that array back in the hash. That means we can write
  # `@listeners[topic] << handler` without first checking whether
  # the topic exists.
  def initialize
    @listeners = Hash.new { |h, k| h[k] = [] }
  end

  # Register a handler block for one topic and return it for later removal.
  def on(topic, &handler)
    @listeners[topic] << handler
    handler
  end

  # Remove one previously-registered handler from a topic.
  def off(topic, handler)
    @listeners[topic].delete(handler)
  end

  # Call every handler for the topic with the supplied arguments.
  # `*args` captures any positional arguments as an array and
  # `**kwargs` captures any keyword arguments as a hash — then we
  # splat them back into each handler's `.call` so handlers can
  # declare whichever signature they want.
  def emit(topic, *args, **kwargs)
    @listeners[topic].each { |h| h.call(*args, **kwargs) }
  end
end

# The `if __FILE__ == $PROGRAM_NAME` idiom means "only run this
# block when the file is executed directly (not when it's
# required by another file)". It lets a file serve as both a
# library and a runnable demo.
if __FILE__ == $PROGRAM_NAME
  bus = EventBus.new

  bus.on(:user_signed_in) { |user:| puts "welcome, #{user}" }
  bus.on(:user_signed_in) { |user:| puts "logging signin for #{user}" }

  bus.emit(:user_signed_in, user: "yosia")
end
