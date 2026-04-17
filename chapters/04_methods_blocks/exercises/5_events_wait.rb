# Exercise 5 — EventBus#wait_for
#
# Add a wait_for(topic) method that BLOCKS the calling code until the next
# emit of `topic`. Returns the args that were emitted.
#
# Hint: a Thread::Queue. Subscribe a handler that pushes args into the queue,
# then queue.pop blocks until something arrives.
#
# Test by emitting from another thread.

require "thread"

class EventBus
  def initialize
    @listeners = Hash.new { |h, k| h[k] = [] }
  end

  def on(topic, &handler)
    @listeners[topic] << handler
    handler
  end

  def emit(topic, *args, **kwargs)
    @listeners[topic].each { |h| h.call(*args, **kwargs) }
  end

  # TODO: def wait_for(topic)
end
