# Exercise 4 — EventBus#once
#
# Add a once(topic, &handler) method. The handler fires at most once, then
# auto-unsubscribes.
#
# Hint: build a wrapper lambda that calls the user's handler then removes
# itself from the listener list.

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

  # TODO: def once(topic, &handler)
end
