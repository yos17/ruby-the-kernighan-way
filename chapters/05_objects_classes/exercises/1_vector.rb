# Exercise 1 — Vector
#
# Build a 3D vector with arithmetic and geometric operations.

class Vector
  attr_reader :x, :y, :z

  def initialize(x, y, z = 0)
    @x = x.to_f
    @y = y.to_f
    @z = z.to_f
  end

  # TODO: def +(other)            — vector addition
  # TODO: def -(other)            — vector subtraction
  # TODO: def *(scalar)           — scalar multiplication
  # TODO: def dot(other)          — dot product (returns a Float)
  # TODO: def magnitude           — sqrt(x*x + y*y + z*z)
  # TODO: def normalize           — Vector with magnitude 1.0
  # TODO: def ==(other)           — true if x/y/z all equal
  # TODO: def to_s                — "(x, y, z)"
end

if __FILE__ == $PROGRAM_NAME
  v1 = Vector.new(1, 2, 3)
  v2 = Vector.new(4, 5, 6)
  # puts v1 + v2     # => (5.0, 7.0, 9.0)
  # puts v1.dot(v2)  # => 32.0
end
