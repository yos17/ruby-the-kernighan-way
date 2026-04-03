# Chapter 5 — Objects and Classes

## What is a Class?

A class is a blueprint for objects. You define what data (attributes) and behavior (methods) objects of that type have.

```ruby
class Dog
  def initialize(name, breed)
    @name  = name    # instance variable
    @breed = breed
  end

  def bark
    "Woof! I'm #{@name}."
  end

  def to_s
    "#{@name} (#{@breed})"
  end
end

rex  = Dog.new("Rex", "German Shepherd")
spot = Dog.new("Spot", "Dalmatian")

rex.bark    # => "Woof! I'm Rex."
puts rex    # => Rex (German Shepherd)  — calls to_s automatically
```

`initialize` is called when you do `Dog.new(...)`. `@name` is an instance variable — each object has its own copy.

---

## `attr_accessor`, `attr_reader`, `attr_writer`

Writing getters and setters by hand is tedious:

```ruby
# Without attr_accessor:
class Dog
  def name
    @name
  end
  def name=(val)
    @name = val
  end
end

# With attr_accessor:
class Dog
  attr_accessor :name, :breed    # getter + setter
  attr_reader   :id              # getter only
  attr_writer   :password        # setter only
end

dog = Dog.new
dog.name = "Rex"
dog.name    # => "Rex"
```

These are **class methods** that generate instance methods. By the end of the metaprogramming chapter, you'll understand how they work internally.

---

## A Real Class: BankAccount

```ruby
class BankAccount
  attr_reader :owner, :balance

  def initialize(owner, initial_balance = 0)
    @owner   = owner
    @balance = initial_balance
    @history = []
  end

  def deposit(amount)
    raise ArgumentError, "Amount must be positive" unless amount > 0
    @balance += amount
    record("Deposit", amount)
    self   # return self for chaining
  end

  def withdraw(amount)
    raise ArgumentError, "Amount must be positive" unless amount > 0
    raise "Insufficient funds" if amount > @balance
    @balance -= amount
    record("Withdrawal", amount)
    self
  end

  def transfer_to(other_account, amount)
    withdraw(amount)
    other_account.deposit(amount)
    self
  end

  def statement
    puts "Account: #{@owner}"
    puts "Balance: $#{"%.2f" % @balance}"
    puts "\nHistory:"
    @history.each do |entry|
      puts "  #{entry[:date].strftime("%Y-%m-%d")} #{entry[:type].ljust(12)} $#{"%.2f" % entry[:amount]}"
    end
  end

  def to_s
    "BankAccount(#{@owner}, $#{"%.2f" % @balance})"
  end

  private

  def record(type, amount)
    @history << { type: type, amount: amount, date: Time.now }
  end
end

account = BankAccount.new("Yosia", 1000)
account.deposit(500).deposit(200).withdraw(100)  # method chaining!
account.statement
```

Key ideas here:
- `raise` throws exceptions (covered in Ch9)
- `private` makes methods internal — callers can't call `account.record(...)`
- `return self` enables **method chaining** — `account.deposit(100).withdraw(50)`

---

## Class Methods and Instance Methods

```ruby
class Circle
  PI = Math::PI    # class constant

  attr_reader :radius

  def initialize(radius)
    @radius = radius
  end

  # Instance method — called on an object
  def area
    PI * @radius ** 2
  end

  def circumference
    2 * PI * @radius
  end

  def >(other)
    area > other.area
  end

  # Class method — called on the class itself
  def self.unit_circle
    new(1)    # 'new' inside the class is Circle.new
  end

  def self.from_diameter(d)
    new(d / 2.0)
  end
end

c1 = Circle.new(5)
c2 = Circle.from_diameter(10)   # class method
c3 = Circle.unit_circle         # class method

c1.area           # => 78.54...
c1 > c2           # => false (defined > operator)
```

`self.method_name` defines a class method. Inside the class (not inside an instance method), `self` refers to the class.

---

## Inheritance

```ruby
class Animal
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def speak
    raise NotImplementedError, "#{self.class} must implement speak"
  end

  def to_s
    "#{self.class.name}(#{@name})"
  end
end

class Dog < Animal
  def speak
    "#{@name} says: Woof!"
  end

  def fetch(item)
    "#{@name} fetches the #{item}!"
  end
end

class Cat < Animal
  def speak
    "#{@name} says: Meow."
  end
end

class GuideDog < Dog
  def initialize(name, owner)
    super(name)    # call parent's initialize
    @owner = owner
  end

  def speak
    super + " (Guide dog for #{@owner})"
  end
end

animals = [Dog.new("Rex"), Cat.new("Whiskers"), GuideDog.new("Buddy", "Yosia")]
animals.each { |a| puts a.speak }
```

`super` calls the parent class's method with the same name. Use it to extend parent behavior.

---

## Comparable — Overriding Operators

```ruby
class Temperature
  include Comparable

  attr_reader :degrees

  def initialize(degrees)
    @degrees = degrees.to_f
  end

  # Define <=> and you get <, >, <=, >=, ==, between?, clamp for free
  def <=>(other)
    degrees <=> other.degrees
  end

  def +(other)
    Temperature.new(degrees + other.degrees)
  end

  def to_s
    "#{degrees}°"
  end
end

temps = [Temperature.new(100), Temperature.new(0), Temperature.new(37)]
temps.sort          # uses <=>
temps.min           # uses <=>
temps.max           # uses <=>

boiling = Temperature.new(100)
freezing = Temperature.new(0)
body = Temperature.new(37)

body.between?(freezing, boiling)   # => true (from Comparable)
```

`include Comparable` + defining `<=>` gives you all comparison operators. This is the power of modules — more in Chapter 6.

---

## Struct — Quick Value Classes

```ruby
Point = Struct.new(:x, :y)
p = Point.new(3, 4)
p.x      # => 3
p.y      # => 4
p.to_a   # => [3, 4]
p == Point.new(3, 4)  # => true (value equality!)

# With methods:
Point = Struct.new(:x, :y) do
  def distance_to(other)
    Math.sqrt((x - other.x)**2 + (y - other.y)**2)
  end

  def to_s
    "(#{x}, #{y})"
  end
end

origin = Point.new(0, 0)
p1     = Point.new(3, 4)
p1.distance_to(origin)   # => 5.0
```

Use Struct when you need a simple value object with attributes but don't need full class machinery.

---

## Object Identity and Equality

```ruby
a = "hello"
b = "hello"
c = a

a == b        # => true   (same value)
a.equal?(b)   # => false  (different objects)
a.equal?(c)   # => true   (same object)
a.object_id == b.object_id  # => false
a.object_id == c.object_id  # => true

# Symbols are always the same object:
:hello.equal?(:hello)    # => true
:hello.object_id == :hello.object_id  # => true
```

---

## `method_missing` — When Methods Don't Exist

When you call a method that doesn't exist, Ruby raises `NoMethodError`. But you can intercept this:

```ruby
class FlexibleHash
  def initialize
    @data = {}
  end

  def method_missing(name, *args)
    if name.to_s.end_with?("=")
      @data[name.to_s.chomp("=").to_sym] = args.first
    else
      @data[name]
    end
  end

  def respond_to_missing?(name, include_private = false)
    true
  end
end

h = FlexibleHash.new
h.name = "Yosia"
h.age  = 30
h.name    # => "Yosia"
h.age     # => 30
```

This is a taste of metaprogramming — covered fully in Chapter 10.

---

## Exercises

1. Build a `Vector` class with `+`, `-`, `*` (scalar), dot product, magnitude, and normalization.
2. Build a `Queue` class backed by an array, with `enqueue`, `dequeue`, `peek`, `empty?`, and `size`.
3. Add `freeze` protection to `BankAccount` — once frozen, no deposits/withdrawals allowed.
4. Build a `Matrix` class for 2x2 matrices with `+`, `*`, `determinant`, and `transpose`.

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| `initialize` | called by `new`, sets up the object |
| `@var` | instance variable — each object has its own |
| `attr_accessor` | generates getter + setter |
| `private` | methods internal to the class |
| `return self` | enables method chaining |
| Class methods | `def self.method_name` |
| Inheritance | `class Child < Parent`, `super` |
| `include Comparable` | define `<=>`, get all comparisons free |
| Struct | quick value classes |
| `method_missing` | intercept undefined method calls |

---

## Solutions

### Exercise 1

```ruby
# Vector class with full arithmetic and geometry operations

class Vector
  attr_reader :x, :y, :z

  def initialize(x, y, z = 0)
    @x, @y, @z = x.to_f, y.to_f, z.to_f
  end

  # Vector addition
  def +(other)
    Vector.new(x + other.x, y + other.y, z + other.z)
  end

  # Vector subtraction
  def -(other)
    Vector.new(x - other.x, y - other.y, z - other.z)
  end

  # Scalar multiplication
  def *(scalar)
    Vector.new(x * scalar, y * scalar, z * scalar)
  end

  # Dot product
  def dot(other)
    x * other.x + y * other.y + z * other.z
  end

  # Magnitude (length)
  def magnitude
    Math.sqrt(x**2 + y**2 + z**2)
  end
  alias length magnitude

  # Normalized unit vector
  def normalize
    mag = magnitude
    raise "Cannot normalize zero vector" if mag == 0
    Vector.new(x / mag, y / mag, z / mag)
  end

  def ==(other)
    x == other.x && y == other.y && z == other.z
  end

  def to_s
    "(#{x}, #{y}, #{z})"
  end

  def to_a
    [x, y, z]
  end
end

# Usage:
v1 = Vector.new(1, 2, 3)
v2 = Vector.new(4, 5, 6)

v1 + v2         # => (5.0, 7.0, 9.0)
v1 - v2         # => (-3.0, -3.0, -3.0)
v1 * 2          # => (2.0, 4.0, 6.0)
v1.dot(v2)      # => 32.0  (1*4 + 2*5 + 3*6)
v1.magnitude    # => 3.7416...  (sqrt(14))
v1.normalize    # => (0.267, 0.535, 0.802)

puts v1 + v2    # => (5.0, 7.0, 9.0)
```

### Exercise 2

```ruby
# Queue class backed by an array

class MyQueue
  def initialize
    @data = []
  end

  # Add to the back of the queue
  def enqueue(item)
    @data.push(item)
    self
  end
  alias << enqueue

  # Remove and return from the front
  def dequeue
    raise "Queue is empty" if empty?
    @data.shift
  end

  # Look at the front without removing
  def peek
    raise "Queue is empty" if empty?
    @data.first
  end

  def empty?
    @data.empty?
  end

  def size
    @data.size
  end

  def to_s
    "Queue(#{@data.join(' → ')})"
  end

  def to_a
    @data.dup
  end
end

# Usage:
q = MyQueue.new
q.enqueue("first").enqueue("second").enqueue("third")
puts q        # => Queue(first → second → third)
puts q.size   # => 3
puts q.peek   # => "first"
q.dequeue     # => "first"
puts q        # => Queue(second → third)
puts q.empty? # => false

# Using << alias:
q << "fourth"
puts q        # => Queue(second → third → fourth)
```

### Exercise 3

```ruby
# BankAccount with freeze protection

class BankAccount
  attr_reader :owner, :balance, :frozen?

  def initialize(owner, initial_balance = 0)
    @owner    = owner
    @balance  = initial_balance
    @history  = []
    @frozen   = false
  end

  def deposit(amount)
    check_frozen!
    raise ArgumentError, "Amount must be positive" unless amount > 0
    @balance += amount
    record("Deposit", amount)
    self
  end

  def withdraw(amount)
    check_frozen!
    raise ArgumentError, "Amount must be positive" unless amount > 0
    raise "Insufficient funds" if amount > @balance
    @balance -= amount
    record("Withdrawal", amount)
    self
  end

  def freeze!
    @frozen = true
    record("Account frozen", 0)
    self
  end

  def unfreeze!
    @frozen = false
    record("Account unfrozen", 0)
    self
  end

  def frozen?
    @frozen
  end

  def to_s
    status = @frozen ? " [FROZEN]" : ""
    "BankAccount(#{@owner}, $#{'%.2f' % @balance}#{status})"
  end

  private

  def check_frozen!
    raise "Account is frozen. No transactions allowed." if @frozen
  end

  def record(type, amount)
    @history << { type: type, amount: amount, date: Time.now }
  end
end

# Usage:
account = BankAccount.new("Yosia", 1000)
account.deposit(500)
puts account         # => BankAccount(Yosia, $1500.00)

account.freeze!
puts account         # => BankAccount(Yosia, $1500.00) [FROZEN]

begin
  account.deposit(100)
rescue RuntimeError => e
  puts e.message     # => Account is frozen. No transactions allowed.
end

account.unfreeze!
account.withdraw(200)
puts account         # => BankAccount(Yosia, $1300.00)
```

### Exercise 4

```ruby
# Matrix class for 2x2 matrices

class Matrix2x2
  attr_reader :a, :b, :c, :d

  # Matrix layout:
  # | a  b |
  # | c  d |

  def initialize(a, b, c, d)
    @a, @b, @c, @d = a.to_f, b.to_f, c.to_f, d.to_f
  end

  def +(other)
    Matrix2x2.new(a + other.a, b + other.b,
                  c + other.c, d + other.d)
  end

  def *(other)
    case other
    when Matrix2x2
      # Standard matrix multiplication
      Matrix2x2.new(
        a * other.a + b * other.c,  a * other.b + b * other.d,
        c * other.a + d * other.c,  c * other.b + d * other.d
      )
    when Numeric
      Matrix2x2.new(a * other, b * other, c * other, d * other)
    end
  end

  def determinant
    a * d - b * c
  end

  def transpose
    Matrix2x2.new(a, c, b, d)
  end

  def inverse
    det = determinant
    raise "Matrix is singular (determinant = 0)" if det == 0
    Matrix2x2.new(d / det, -b / det, -c / det, a / det)
  end

  def ==(other)
    [a, b, c, d] == [other.a, other.b, other.c, other.d]
  end

  def to_s
    "|#{a.to_i} #{b.to_i}|\n|#{c.to_i} #{d.to_i}|"
  end
end

# Usage:
m1 = Matrix2x2.new(1, 2, 3, 4)
m2 = Matrix2x2.new(5, 6, 7, 8)

puts m1 + m2
# |6 8|
# |10 12|

puts m1 * m2
# |19 22|
# |43 50|

puts "det: #{m1.determinant}"   # => det: -2.0
puts m1.transpose
# |1 3|
# |2 4|
```
