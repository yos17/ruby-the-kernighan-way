# events.rb — a minimal pub/sub event bus
# Usage: ruby events.rb (demo)

class EventBus
  # Start with an empty listener list for every topic.
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
  def emit(topic, *args, **kwargs)
    @listeners[topic].each { |h| h.call(*args, **kwargs) }
  end
end

if __FILE__ == $PROGRAM_NAME
  bus = EventBus.new

  bus.on(:user_signed_in) { |user:| puts "welcome, #{user}" }
  bus.on(:user_signed_in) { |user:| puts "logging signin for #{user}" }

  bus.emit(:user_signed_in, user: "yosia")
end
