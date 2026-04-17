# Solution to Exercise 4
module Registerable
  def self.classes
    @classes ||= []
  end

  def self.included(klass)
    classes << klass
  end
end

if __FILE__ == $PROGRAM_NAME
  class A; include Registerable; end
  class B; include Registerable; end

  puts Registerable.classes.inspect   # => [A, B]
end
