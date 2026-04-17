# events.rb — a minimal pub/sub event bus
# Usage: ruby events.rb (demo)

class EventBus
  def initialize
    @listeners = Hash.new { |h, k| h[k] = [] }
  end

  def on(topic, &handler)
    @listeners[topic] << handler
    handler
  end

  def off(topic, handler)
    @listeners[topic].delete(handler)
  end

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
