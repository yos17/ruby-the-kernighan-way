# Solution to Exercise 1
class Vector
  attr_reader :x, :y, :z

  def initialize(x, y, z = 0)
    @x = x.to_f
    @y = y.to_f
    @z = z.to_f
  end

  def +(other)  = Vector.new(x + other.x, y + other.y, z + other.z)
  def -(other)  = Vector.new(x - other.x, y - other.y, z - other.z)
  def *(scalar) = Vector.new(x * scalar, y * scalar, z * scalar)
  def dot(other) = x * other.x + y * other.y + z * other.z
  def magnitude = Math.sqrt(x ** 2 + y ** 2 + z ** 2)

  def normalize
    m = magnitude
    raise "cannot normalize zero vector" if m.zero?
    Vector.new(x / m, y / m, z / m)
  end

  def ==(other) = other.is_a?(Vector) && x == other.x && y == other.y && z == other.z
  def to_s      = "(#{x}, #{y}, #{z})"
end

if __FILE__ == $PROGRAM_NAME
  v1 = Vector.new(1, 2, 3)
  v2 = Vector.new(4, 5, 6)
  puts v1 + v2
  puts v1.dot(v2)
  puts v1.magnitude
  puts v1.normalize
end
