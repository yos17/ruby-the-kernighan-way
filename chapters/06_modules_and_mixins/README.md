# Chapter 6 — Modules and Mixins

## The Problem Inheritance Can't Solve

Inheritance gives you one parent. But what if a class needs behaviors from multiple sources?

A `Duck` is an `Animal`. But it also `Swims`, `Flies`, and `Quacks`. If `Swimming`, `Flying`, and `Quacking` are all different classes, you can't inherit from all of them in Ruby (no multiple inheritance).

Modules solve this. A module is a collection of methods you can **mix into** any class.

---

## Defining and Including a Module

```ruby
module Greetable
  def greet
    "Hello, I'm #{name}"     # assumes the class has a 'name' method
  end

  def farewell
    "Goodbye from #{name}"
  end
end

module Serializable
  def to_json
    vars = instance_variables.map do |var|
      key   = var.to_s.delete("@")
      value = instance_variable_get(var)
      "\"#{key}\": #{value.inspect}"
    end
    "{ #{vars.join(", ")} }"
  end
end

class Person
  include Greetable
  include Serializable

  attr_reader :name, :age

  def initialize(name, age)
    @name = name
    @age  = age
  end
end

p = Person.new("Yosia", 30)
p.greet      # => "Hello, I'm Yosia"
p.to_json    # => { "name": "Yosia", "age": 30 }
```

`include` adds module methods as **instance methods**.

---

## `extend` vs `include` vs `prepend`

```ruby
module ClassMethods
  def create_with_defaults
    new("default", 0)
  end
end

module InstanceMethods
  def describe
    "I am #{self.class}"
  end
end

module LoggingBehavior
  def save
    puts "Saving #{self}..."
    result = super      # call the next method in the chain
    puts "Saved!"
    result
  end
end

class User
  include InstanceMethods    # adds as instance methods
  extend ClassMethods        # adds as class methods
  prepend LoggingBehavior    # wraps existing methods
end

User.create_with_defaults    # class method
User.new.describe            # instance method
```

| Method | Effect |
|--------|--------|
| `include` | adds module methods as instance methods |
| `extend` | adds module methods as class methods |
| `prepend` | inserts module BEFORE the class in method lookup — can wrap methods |

---

## `self.included` — The Hook Pattern

When a module is included, Ruby calls `self.included(base)` on the module. Use this to automatically extend the class with class methods:

```ruby
module Findable
  def self.included(base)
    base.extend(ClassMethods)    # also add class methods when included
  end

  # Instance methods
  def reload
    self.class.find(id)
  end

  # Class methods (added via extend)
  module ClassMethods
    def find(id)
      puts "Finding #{self} ##{id}"
      # ... database query
    end

    def find_all
      puts "Finding all #{self}"
    end
  end
end

class Post
  include Findable
end

Post.find(5)         # class method
Post.find_all        # class method
Post.new.reload      # instance method
```

This pattern — `include` adding both instance AND class methods — is how Rails Concerns work.

---

## Comparable — A Built-in Module

```ruby
class Box
  include Comparable

  attr_reader :volume

  def initialize(l, w, h)
    @volume = l * w * h
  end

  def <=>(other)
    volume <=> other.volume
  end
end

boxes = [Box.new(3,3,3), Box.new(1,2,3), Box.new(5,5,5)]
boxes.sort          # uses <=>
boxes.min           # smallest by volume
boxes.max           # largest by volume
Box.new(2,2,2).between?(Box.new(1,1,1), Box.new(3,3,3))  # => true
```

---

## Enumerable — The Most Useful Module

Include `Enumerable` in any class that holds a collection. You only need to define `each`:

```ruby
class WordCollection
  include Enumerable

  def initialize
    @words = []
  end

  def add(word)
    @words << word
    self
  end

  def each(&block)
    @words.each(&block)
  end
end

wc = WordCollection.new
wc.add("hello").add("world").add("ruby").add("programming")

wc.map(&:upcase)           # ["HELLO", "WORLD", "RUBY", "PROGRAMMING"]
wc.select { |w| w.length > 4 }  # ["hello", "world", "programming"]
wc.sort                    # alphabetical
wc.min_by(&:length)        # shortest word
wc.group_by(&:length)      # grouped by length
wc.any? { |w| w.start_with?("r") }  # => true
wc.count { |w| w.length > 4 }       # => 3
wc.to_a                    # ["hello", "world", "ruby", "programming"]
```

One `each` method → 50+ methods for free. This is mixin power.

---

## Modules as Namespaces

Modules prevent name collisions:

```ruby
module Payments
  class User
    def initialize(name)
      @name = name
    end
  end

  class Transaction
    def initialize(amount)
      @amount = amount
    end
  end
end

module Analytics
  class User
    def initialize(id)
      @id = id
    end
  end
end

Payments::User.new("Yosia")      # Payments::User
Analytics::User.new(42)          # Analytics::User — no collision
```

Rails uses namespacing: `ActiveRecord::Base`, `ActionController::Base`, `ActionView::Base`.

---

## A Real Mixin: Logging

```ruby
module Logging
  def log(level, message)
    prefix = case level
             when :info  then "\e[32m[INFO] \e[0m"
             when :warn  then "\e[33m[WARN] \e[0m"
             when :error then "\e[31m[ERROR]\e[0m"
             else             "[LOG]  "
             end
    timestamp = Time.now.strftime("%H:%M:%S")
    STDOUT.puts "#{timestamp} #{prefix} #{self.class}: #{message}"
  end

  def log_info(msg);  log(:info, msg);  end
  def log_warn(msg);  log(:warn, msg);  end
  def log_error(msg); log(:error, msg); end
end

class PaymentProcessor
  include Logging

  def process(amount)
    log_info "Processing payment of $#{amount}"
    # ... do work
    log_info "Payment complete"
  rescue => e
    log_error "Payment failed: #{e.message}"
    raise
  end
end

class EmailSender
  include Logging

  def send_email(to, subject)
    log_info "Sending email to #{to}: #{subject}"
    # ... send
  end
end

# Both classes get logging with zero duplication
```

---

## Your Program: A Plugin System

```ruby
# plugin_system.rb — modules as runtime-loadable plugins

module Plugin
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_variable_set(:@plugins, [])
  end

  module ClassMethods
    def register_plugin(name, &block)
      plugin_module = Module.new
      plugin_module.define_method(name, &block)
      include plugin_module
      @plugins << name
      puts "Plugin '#{name}' registered for #{self}"
    end

    def plugins
      @plugins
    end
  end
end

class TextProcessor
  include Plugin

  def initialize(text)
    @text = text
  end

  register_plugin(:word_count) do
    @text.split.length
  end

  register_plugin(:char_count) do
    @text.length
  end

  register_plugin(:uppercase) do
    @text.upcase
  end
end

# Add plugins at runtime!
TextProcessor.register_plugin(:reversed) do
  @text.reverse
end

tp = TextProcessor.new("Hello, Ruby World!")
puts tp.word_count    # => 3
puts tp.char_count    # => 18
puts tp.uppercase     # => HELLO, RUBY WORLD!
puts tp.reversed      # => !dlroW ybuR ,olleH
puts TextProcessor.plugins  # => [:word_count, :char_count, :uppercase, :reversed]
```

---

## Exercises

1. Build a `Cacheable` module: include it in a class, and it caches method results (memoization for any method).
2. Build a `Validatable` module: `validates :email, format: /regex/` stored as class config.
3. Build a `Timestampable` module: automatically adds `created_at` and `updated_at` instance variables, set on `save`.
4. Create a `Describable` module that adds a `.description` class method for documentation.

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| Module | a collection of methods, can't be instantiated |
| `include` | adds methods as instance methods |
| `extend` | adds methods as class methods |
| `prepend` | inserts before class in method lookup — wraps methods |
| `self.included` | hook called when module is included |
| `Comparable` | define `<=>`, get all comparisons free |
| `Enumerable` | define `each`, get 50+ collection methods free |
| Namespace | `module Foo; class Bar; end; end` → `Foo::Bar` |
| Mixin | reusable behavior injected into any class |

---

## Solutions

### Exercise 1

```ruby
# Cacheable module — memoization for any method via a class macro

module Cacheable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def cache_method(*method_names)
      method_names.each do |name|
        original = instance_method(name)

        define_method(name) do |*args|
          @_cache       ||= {}
          @_cache[name] ||= {}
          key = args

          unless @_cache[name].key?(key)
            @_cache[name][key] = original.bind(self).call(*args)
          end
          @_cache[name][key]
        end
      end
    end
  end

  def clear_cache(method_name = nil)
    @_cache ||= {}
    method_name ? @_cache.delete(method_name) : @_cache.clear
  end
end

# Usage:
class Calculator
  include Cacheable

  def expensive_fib(n)
    puts "Computing fib(#{n})..."   # shows when actually computed
    return n if n <= 1
    expensive_fib(n - 1) + expensive_fib(n - 2)
  end

  cache_method :expensive_fib
end

calc = Calculator.new
calc.expensive_fib(5)   # computes: fib(0)..fib(5)
calc.expensive_fib(5)   # => from cache, no output
calc.expensive_fib(3)   # => from cache, no output
```

### Exercise 2

```ruby
# Validatable module — validates :field, presence: true, format: /regex/

module Validatable
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_variable_set(:@validations, {})
  end

  module ClassMethods
    def validates(field, **rules)
      @validations        ||= {}
      @validations[field] ||= []
      @validations[field] << rules
    end

    def validations
      @validations
    end
  end

  def valid?
    @errors = []
    self.class.validations.each do |field, rules_list|
      value = send(field) rescue nil
      rules_list.each do |rules|
        if rules[:presence] && (value.nil? || value.to_s.strip.empty?)
          @errors << "#{field} can't be blank"
        end
        if rules[:format] && !value.nil? && !value.match?(rules[:format])
          @errors << "#{field} is invalid"
        end
        if rules[:length] && !value.nil?
          range = rules[:length]
          @errors << "#{field} is too short (min #{range.min})" if range.is_a?(Range) && value.length < range.min
          @errors << "#{field} is too long (max #{range.max})"  if range.is_a?(Range) && value.length > range.max
        end
        if rules[:numericality] && !value.nil?
          @errors << "#{field} must be a number" unless value.is_a?(Numeric)
        end
      end
    end
    @errors.empty?
  end

  def errors
    @errors || []
  end
end

# Usage:
class User
  include Validatable

  attr_accessor :name, :email, :age

  validates :name,  presence: true, length: (2..50)
  validates :email, presence: true, format: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :age,   numericality: true

  def initialize(name:, email:, age:)
    @name, @email, @age = name, email, age
  end
end

u = User.new(name: "Yosia", email: "yosia@example.com", age: 30)
u.valid?    # => true
u.errors    # => []

bad = User.new(name: "", email: "not-an-email", age: "old")
bad.valid?  # => false
bad.errors  # => ["name can't be blank", "email is invalid", "age must be a number"]
```

### Exercise 3

```ruby
# Timestampable module — auto-sets created_at/updated_at on save

module Timestampable
  def self.included(base)
    base.class_eval do
      attr_reader :created_at, :updated_at
    end
  end

  def save
    now = Time.now
    @created_at ||= now   # only set on first save
    @updated_at   = now
    super rescue nil       # call super if the class defines save; ignore if not
    self
  end

  def touch
    @updated_at = Time.now
    self
  end
end

# Usage:
class Article
  include Timestampable

  attr_accessor :title, :content

  def initialize(title, content)
    @title   = title
    @content = content
  end
end

article = Article.new("Ruby Mixins", "Modules are powerful...")
article.created_at   # => nil (not saved yet)

article.save
article.created_at   # => 2026-04-03 10:08:00 +0200
article.updated_at   # => 2026-04-03 10:08:00 +0200

sleep 0.01
article.touch
# article.updated_at > article.created_at  # => true
```

### Exercise 4

```ruby
# Describable module — adds .description class method for documentation

module Describable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def description(text = nil)
      if text
        @description = text
      else
        @description || "No description provided for #{name}"
      end
    end

    def describe
      lines = ["#{name}: #{description}"]
      public_instance_methods(false).sort.each do |m|
        lines << "  ##{m}"
      end
      lines.join("\n")
    end
  end
end

# Usage:
class PaymentProcessor
  include Describable

  description "Handles payment processing for orders"

  def process(amount) = "Processing $#{amount}"
  def refund(amount)  = "Refunding $#{amount}"
  def void            = "Voiding transaction"
end

puts PaymentProcessor.description
# => "Handles payment processing for orders"

puts PaymentProcessor.describe
# PaymentProcessor: Handles payment processing for orders
#   #process
#   #refund
#   #void
```
