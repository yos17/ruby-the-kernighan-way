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
