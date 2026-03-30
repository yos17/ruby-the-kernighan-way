# Chapter 10 — Metaprogramming

## What is Metaprogramming?

Metaprogramming means **writing code that writes code**. In Ruby, you can:
- Define methods at runtime
- Add methods to existing classes
- Call methods by name
- Inspect and modify objects and classes while the program is running

This is what makes Rails possible. When you write `belongs_to :user`, that's not a keyword — it's a method that *generates other methods* at class-definition time.

Let's learn how.

---

## 1. Open Classes

Every class in Ruby can be reopened at any time:

```ruby
class String
  def word_count
    split.length
  end

  def palindrome?
    stripped = downcase.gsub(/[^a-z0-9]/, '')
    stripped == stripped.reverse
  end
end

"Hello World".word_count    # => 2
"racecar".palindrome?       # => true
"A man a plan a canal Panama".palindrome?  # => true

# Rails does this constantly:
# 5.days.ago, "hello_world".camelize, etc.
```

This is called **monkey patching**. Use carefully — reopening core classes globally affects all code.

---

## 2. `respond_to?` and `send`

```ruby
obj = "hello"
obj.respond_to?(:upcase)     # => true
obj.respond_to?(:fly)        # => false
obj.respond_to?(:secret, true)  # check private methods too

# send — call a method by name (string or symbol)
"hello".send(:upcase)        # => "HELLO"
"hello".send(:[], 1)         # => "e"
42.send(:+, 8)               # => 50

# send can call private methods too (careful!)
class Secret
  private
  def hidden
    "shhh"
  end
end

Secret.new.send(:hidden)     # => "shhh"  (bypasses private)
Secret.new.public_send(:hidden)  # raises NoMethodError (respects private)

# Why is send useful?
# When you have the method name as a variable:
method_name = "upcase"
"hello".send(method_name)    # => "HELLO"

# Rails routing uses this:
controller.send(action_name)   # calls :index, :show, etc.
```

---

## 3. `define_method` — Create Methods Dynamically

Instead of writing 10 similar methods, generate them:

```ruby
class Color
  COLORS = %i[red green blue yellow purple orange]

  # Generate: red!, green!, blue!... and red?, green?, blue?...
  COLORS.each do |color|
    define_method("#{color}!") do
      @current = color
    end

    define_method("#{color}?") do
      @current == color
    end
  end

  def current
    @current
  end
end

c = Color.new
c.red!
c.red?    # => true
c.blue?   # => false
c.blue!
c.blue?   # => true

# This is how Rails generates methods like:
#   post.published!
#   post.published?
#   post.draft!
```

---

## 4. `method_missing` and `respond_to_missing?`

When a method doesn't exist, Ruby calls `method_missing`:

```ruby
class DynamicProxy
  def initialize(target)
    @target = target
  end

  def method_missing(name, *args, &block)
    if @target.respond_to?(name)
      puts "Calling #{name} on #{@target.class}"
      @target.send(name, *args, &block)
    else
      super   # let Ruby raise NoMethodError normally
    end
  end

  def respond_to_missing?(name, include_private = false)
    @target.respond_to?(name, include_private) || super
  end
end

proxy = DynamicProxy.new("hello world")
proxy.upcase      # Calling upcase on String  => "HELLO WORLD"
proxy.split       # Calling split on String   => ["hello", "world"]
proxy.length      # Calling length on String  => 11
proxy.nonexistent # NoMethodError (goes to super)

proxy.respond_to?(:upcase)   # => true (from respond_to_missing?)
```

### Real example: `find_by_*`

```ruby
class Record
  def self.method_missing(name, *args)
    if name.to_s.start_with?("find_by_")
      field = name.to_s.sub("find_by_", "")
      find_by(field => args.first)
    else
      super
    end
  end

  def self.respond_to_missing?(name, include_private = false)
    name.to_s.start_with?("find_by_") || super
  end

  def self.find_by(conditions)
    puts "SELECT * WHERE #{conditions.map { |k,v| "#{k}='#{v}'" }.join(' AND ')}"
  end
end

Record.find_by_email("yosia@example.com")
# SELECT * WHERE email='yosia@example.com'

Record.find_by_name_and_city("Yosia", "Amsterdam")
# Hmm — you could even parse compound names!
```

---

## 5. `instance_variable_get/set` — Access Instance Variables by Name

```ruby
class Person
  def initialize(name, age)
    @name = name
    @age  = age
  end
end

p = Person.new("Yosia", 30)

p.instance_variable_get(:@name)      # => "Yosia"
p.instance_variable_get(:@age)       # => 30
p.instance_variables                 # => [:@name, :@age]

p.instance_variable_set(:@name, "Alex")
p.instance_variable_get(:@name)      # => "Alex"

# Useful for generic serialization:
def to_hash(obj)
  obj.instance_variables.each_with_object({}) do |var, h|
    h[var.to_s.delete("@").to_sym] = obj.instance_variable_get(var)
  end
end

to_hash(Person.new("Yosia", 30))
# => { name: "Yosia", age: 30 }
```

---

## 6. `class_eval` and `instance_eval`

**`class_eval`** — open a class and add methods (when you have the class as a variable):

```ruby
# These are identical:
class Dog
  def bark; "Woof"; end
end

Dog.class_eval do
  def bark; "Woof"; end
end

# When you have the class in a variable:
[String, Integer, Array].each do |klass|
  klass.class_eval do
    def type_name
      self.class.name
    end
  end
end

"hello".type_name   # => "String"
42.type_name        # => "Integer"
```

**`instance_eval`** — run code in the context of a specific object:

```ruby
obj = Object.new

obj.instance_eval do
  def hello
    "Hello from singleton method!"
  end

  @secret = 42
end

obj.hello            # => "Hello from singleton method!"
obj.instance_variable_get(:@secret)  # => 42

# instance_eval is how DSLs work:
class Router
  def draw(&block)
    instance_eval(&block)  # block runs with 'self' = the router
  end

  def get(path)
    puts "Registering GET #{path}"
  end
end

Router.new.draw do
  get "/posts"    # calls self.get, which is router.get
  get "/users"
end
```

---

## 7. `define_singleton_method` — Methods on One Object

```ruby
obj = Object.new

obj.define_singleton_method(:hello) do
  "Hello from just this object"
end

obj.hello   # => "Hello from just this object"
Object.new.hello   # NoMethodError — only this one object has it

# Useful for adding behavior to specific instances:
def make_admin(user)
  user.define_singleton_method(:admin?) { true }
  user.define_singleton_method(:admin_dashboard) { "Secret dashboard" }
  user
end
```

---

## 8. `const_get` and `const_set` — Dynamic Constants

```ruby
Object.const_get("String")      # => String (the class)
Object.const_get("Enumerable")  # => Enumerable

# Look up a constant by name:
class_name = "PostsController"
klass = Object.const_get(class_name)
klass.new    # => #<PostsController:...>

# Rails uses this for routing:
# "posts#index" → PostsController → controller.index

# const_set — define a constant dynamically:
Object.const_set("MyDynamicClass", Class.new do
  def hello; "dynamic!"; end
end)

MyDynamicClass.new.hello   # => "dynamic!"
```

---

## 9. Hooks — `included`, `extended`, `inherited`

Ruby calls these methods automatically at class/module moments:

```ruby
module Observable
  def self.included(base)
    puts "#{self} was included in #{base}"
    base.extend(ClassMethods)
    base.instance_variable_set(:@observers, [])
  end

  module ClassMethods
    def observe_with(observer)
      @observers << observer
    end

    def observers
      @observers
    end
  end

  def notify_observers(event, data = nil)
    self.class.observers.each { |obs| obs.call(event, data) }
  end
end

class Order
  include Observable

  observe_with ->(event, data) { puts "Order event: #{event} - #{data}" }

  def place
    # ... place order
    notify_observers(:placed, total: 99.99)
  end
end
```

```ruby
# inherited — called when a class is subclassed
class Plugin
  @registry = []

  def self.inherited(subclass)
    @registry << subclass
    puts "New plugin registered: #{subclass}"
  end

  def self.all
    @registry
  end
end

class LoggingPlugin < Plugin; end
class CachePlugin < Plugin; end

Plugin.all   # => [LoggingPlugin, CachePlugin]
```

---

## 10. Building `attr_accessor` from Scratch

Now you understand enough to implement Ruby's own `attr_accessor`:

```ruby
module AttributeMethods
  def attr_reader(*names)
    names.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end
    end
  end

  def attr_writer(*names)
    names.each do |name|
      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
      end
    end
  end

  def attr_accessor(*names)
    attr_reader(*names)
    attr_writer(*names)
  end
end

# Make it available to all classes:
Class.include(AttributeMethods)

# Now works like built-in:
class Person
  attr_accessor :name, :age
end

p = Person.new
p.name = "Yosia"
p.age  = 30
p.name  # => "Yosia"
```

---

## Your Project: Build `has_attribute` (Like ActiveRecord)

```ruby
# attributes.rb — a mini ActiveRecord attribute system

module Attributes
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_variable_set(:@attribute_definitions, {})
  end

  module ClassMethods
    # has_attribute :name, type: String, default: nil
    def has_attribute(name, type: nil, default: nil, required: false)
      @attribute_definitions[name] = { type: type, default: default, required: required }

      # Getter
      define_method(name) do
        val = @attributes[name]
        val.nil? ? default : val
      end

      # Setter with type coercion
      define_method("#{name}=") do |value|
        if type && !value.nil? && !value.is_a?(type)
          begin
            value = type.new(value.to_s)
          rescue
            raise TypeError, "#{name} must be #{type}, got #{value.class}"
          end
        end
        @attributes[name] = value
      end

      # Predicate method for booleans
      if type == :boolean
        define_method("#{name}?") { !!send(name) }
      end
    end

    def attribute_definitions
      @attribute_definitions
    end
  end

  def initialize(attrs = {})
    @attributes = {}
    attrs.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
  end

  def valid?
    @errors = []
    self.class.attribute_definitions.each do |name, opts|
      value = send(name)
      if opts[:required] && (value.nil? || value.to_s.strip.empty?)
        @errors << "#{name} is required"
      end
    end
    @errors.empty?
  end

  def errors
    @errors || []
  end

  def to_h
    self.class.attribute_definitions.keys.each_with_object({}) do |name, h|
      h[name] = send(name)
    end
  end

  def to_s
    "#{self.class.name}(#{to_h.map { |k,v| "#{k}: #{v.inspect}" }.join(', ')})"
  end
end

# --- Use it ---

class Product
  include Attributes

  has_attribute :name,        type: String, required: true
  has_attribute :price,       type: Float,  default: 0.0
  has_attribute :in_stock,    type: :boolean, default: true
  has_attribute :description, type: String
end

p = Product.new(name: "Ruby Book", price: 39.99)
puts p.name       # => "Ruby Book"
puts p.price      # => 39.99
puts p.in_stock?  # => true

p.name = "Learn Ruby"
puts p            # => Product(name: "Learn Ruby", price: 39.99, ...)

bad = Product.new(price: 9.99)
bad.valid?        # => false
bad.errors        # => ["name is required"]
```

---

## Exercises

1. Build `validates` from scratch — `validates :email, presence: true, format: /regex/`
2. Build `memoize` — a class macro that caches expensive method results: `memoize :fibonacci`
3. Build `delegator` — `delegate :name, to: :user` generates a `name` method that calls `user.name`
4. Build `observable` — `on(:save) { |obj| ... }` registers a callback, triggered when `save` is called
5. Build a simple DSL for defining HTML: `html { head { title "Hello" }; body { p "World" } }`

---

## What You Learned

| Technique | What it does | Rails uses it for |
|-----------|-------------|-------------------|
| Open classes | reopen and add methods to any class | `.days`, `.ago`, `.camelize` |
| `send` | call method by name | dispatch to controller actions |
| `define_method` | create methods in a loop | attr_accessor, `red?`, `red!` |
| `method_missing` | catch undefined calls | `find_by_email`, dynamic finders |
| `respond_to_missing?` | tell Ruby about ghost methods | paired with method_missing |
| `instance_variable_get/set` | access ivar by name | serialization, ORMs |
| `class_eval` | open a class by variable | adding methods to model classes |
| `instance_eval` | run block in object's context | DSLs (routes, config) |
| `define_singleton_method` | add method to one object | per-instance behavior |
| `const_get` | look up a class by name | Rails controller routing |
| `included` hook | called when module is included | setting up class methods |
| `inherited` hook | called when class is subclassed | plugin/registry systems |
