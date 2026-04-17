# Exercise 2 — MyQueue
#
# A FIFO queue backed by an array.

class MyQueue
  include Enumerable

  def initialize
    @data = []
  end

  # TODO: def enqueue(item)  — push to back; return self
  # TODO: alias <<            — same as enqueue
  # TODO: def dequeue          — remove and return front; raise if empty
  # TODO: def peek             — return front without removing; raise if empty
  # TODO: def empty?
  # TODO: def size
  # TODO: def each(&block)     — yields items in FIFO order
end
