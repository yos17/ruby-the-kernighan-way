# Solution to Exercise 4
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
    @listeners[topic].dup.each { |h| h.call(*args, **kwargs) }
  end

  def once(topic, &handler)
    wrapper = nil
    wrapper = ->(*a, **kw) {
      handler.call(*a, **kw)
      off(topic, wrapper)
    }
    @listeners[topic] << wrapper
    wrapper
  end
end

if __FILE__ == $PROGRAM_NAME
  bus = EventBus.new
  bus.once(:ping) { puts "pong" }

  bus.emit(:ping)   # => pong
  bus.emit(:ping)   # nothing — handler unsubscribed
end
