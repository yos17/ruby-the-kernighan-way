# Solution to Exercise 2
class MyQueue
  include Enumerable

  def initialize
    @data = []
  end

  def enqueue(item)
    @data.push(item)
    self
  end
  alias_method :<<, :enqueue

  def dequeue
    raise "queue is empty" if empty?
    @data.shift
  end

  def peek
    raise "queue is empty" if empty?
    @data.first
  end

  def empty? = @data.empty?
  def size   = @data.size
  def each(&block) = @data.each(&block)
end

if __FILE__ == $PROGRAM_NAME
  q = MyQueue.new
  q << "a" << "b" << "c"
  puts q.peek      # a
  puts q.dequeue   # a
  puts q.dequeue   # b
  puts q.size      # 1
  puts q.to_a.inspect
end
