# Solution to Exercise 5
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
    @listeners[topic].dup.each { |h| h.call(*args, **kwargs) }
  end

  def wait_for(topic)
    queue = Thread::Queue.new
    on(topic) { |*a, **kw| queue.push([a, kw]) }
    queue.pop
  end
end

if __FILE__ == $PROGRAM_NAME
  bus = EventBus.new

  Thread.new do
    sleep 0.1
    bus.emit(:hello, "world", from: "thread")
  end

  args, kwargs = bus.wait_for(:hello)
  puts "received args=#{args.inspect} kwargs=#{kwargs.inspect}"
end
