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

---

## Solutions

### Exercise 1

```ruby
# validates — build from scratch with presence, format, length, etc.
# Shows the "naive approach" vs meta approach

# --- NAIVE APPROACH (without metaprogramming) ---
class UserNaive
  attr_accessor :name, :email

  def valid?
    errors = []
    errors << "name can't be blank"            if name.nil? || name.strip.empty?
    errors << "name is too short (min 2 chars)" if name && name.length < 2
    errors << "email can't be blank"            if email.nil? || email.strip.empty?
    errors << "email format is invalid"         if email && !email.match?(/\A\S+@\S+\.\S+\z/)
    @errors = errors
    errors.empty?
  end
end
# Problem: every class needs its own valid? logic. Lots of repetition.

# --- META APPROACH (class macro via define_method) ---
module Validations
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_variable_set(:@rules, [])
  end

  module ClassMethods
    def validates(field, **options)
      @rules ||= []
      @rules  << { field: field, options: options }
    end

    def rules
      @rules
    end
  end

  def valid?
    @errors = []
    self.class.rules.each do |rule|
      field   = rule[:field]
      options = rule[:options]
      value   = send(field)

      if options[:presence]
        if value.nil? || (value.respond_to?(:strip) && value.strip.empty?)
          @errors << "#{field} can't be blank"
          next   # skip other checks if blank
        end
      end

      next if value.nil?

      if (fmt = options[:format])
        @errors << "#{field} is invalid" unless value.to_s.match?(fmt)
      end

      if (range = options[:length])
        @errors << "#{field} is too short (min #{range.min})" if value.length < range.min
        @errors << "#{field} is too long (max #{range.max})"  if value.length > range.max
      end

      if options[:numericality]
        @errors << "#{field} must be a number" unless value.is_a?(Numeric)
      end

      if (in_list = options[:inclusion])
        @errors << "#{field} must be one of: #{in_list.join(', ')}" unless in_list.include?(value)
      end
    end
    @errors.empty?
  end

  def errors
    @errors || []
  end
end

# Usage — clean DSL, no repeated logic:
class User
  include Validations

  attr_accessor :name, :email, :role, :age

  validates :name,  presence: true, length: (2..50)
  validates :email, presence: true, format: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :role,  inclusion: %w[admin user guest]
  validates :age,   numericality: true

  def initialize(attrs = {})
    attrs.each { |k, v| send("#{k}=", v) }
  end
end

u = User.new(name: "Yosia", email: "yosia@example.com", role: "admin", age: 30)
u.valid?    # => true

bad = User.new(name: "X", email: "invalid", role: "superuser", age: "old")
bad.valid?  # => false
bad.errors  # => ["name is too short (min 2 chars)", "email is invalid",
            #     "role must be one of: admin, user, guest", "age must be a number"]
```

### Exercise 2

```ruby
# memoize — class macro that caches expensive method results

# --- NAIVE APPROACH ---
class FibNaive
  def fibonacci(n)
    @fib_cache ||= {}
    @fib_cache[n] ||= begin
      return n if n <= 1
      fibonacci(n - 1) + fibonacci(n - 2)
    end
  end
  # Problem: must manually add caching logic to every method
end

# --- META APPROACH (class macro) ---
module Memoizable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def memoize(*method_names)
      method_names.each do |name|
        # Store the original unbounded method
        original = instance_method(name)

        define_method(name) do |*args|
          @_memo_cache       ||= {}
          @_memo_cache[name] ||= {}

          # Use the arguments as the cache key
          unless @_memo_cache[name].key?(args)
            @_memo_cache[name][args] = original.bind(self).call(*args)
          end
          @_memo_cache[name][args]
        end
      end
    end
  end
end

# Usage:
class Math
  include Memoizable

  def fibonacci(n)
    return n if n <= 1
    fibonacci(n - 1) + fibonacci(n - 2)
  end

  def factorial(n)
    return 1 if n <= 1
    n * factorial(n - 1)
  end

  memoize :fibonacci, :factorial   # one line caches both methods
end

m = Math.new
m.fibonacci(35)   # => 9227465 (fast with memoization)
m.fibonacci(35)   # => 9227465 (from cache, instant)
m.factorial(10)   # => 3628800
```

### Exercise 3

```ruby
# delegator — delegate :method, to: :target_object

# --- NAIVE APPROACH ---
class OrderNaive
  def initialize(user)
    @user = user
  end

  def name  = @user.name
  def email = @user.email
  def age   = @user.age
  # Problem: tedious to write, easy to forget one
end

# --- META APPROACH ---
module Delegatable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def delegate(*methods, to:)
      target = to   # capture in closure

      methods.each do |method_name|
        define_method(method_name) do |*args, &block|
          receiver = send(target)
          raise "#{target} is nil for delegation of #{method_name}" if receiver.nil?
          receiver.send(method_name, *args, &block)
        end
      end
    end
  end
end

# Usage:
User = Struct.new(:name, :email, :age)

class Order
  include Delegatable

  attr_reader :total, :user

  delegate :name, :email, :age, to: :user   # one line, DRY

  def initialize(user, total)
    @user  = user
    @total = total
  end
end

user  = User.new("Yosia", "yosia@example.com", 30)
order = Order.new(user, 99.99)

order.name    # => "Yosia"   (delegated to order.user.name)
order.email   # => "yosia@example.com"
order.age     # => 30
order.total   # => 99.99     (own method)
```

### Exercise 4

```ruby
# observable — on(:save) { |obj| ... } callback system

# --- NAIVE APPROACH ---
class ArticleNaive
  def save
    # ... save logic ...
    after_save_callback.call(self) if @after_save_callback
  end
  # Problem: one callback per event, can't register multiple
end

# --- META APPROACH ---
module Observable
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_variable_set(:@_callbacks, Hash.new { |h, k| h[k] = [] })
  end

  module ClassMethods
    def on(event, &block)
      @_callbacks[event] << block
    end

    def callbacks
      @_callbacks
    end
  end

  def trigger(event, *args)
    self.class.callbacks[event].each { |cb| cb.call(self, *args) }
  end
end

# Usage:
class Article
  include Observable

  attr_accessor :title, :published

  on(:save)    { |a|   puts "Article '#{a.title}' saved to database" }
  on(:save)    { |a|   puts "Cache invalidated for #{a.title}" }
  on(:publish) { |a|   puts "Email sent: '#{a.title}' is now live!" }
  on(:publish) { |a,t| puts "Published at #{t}" }

  def initialize(title)
    @title     = title
    @published = false
  end

  def save
    # ... save logic ...
    trigger(:save)
    self
  end

  def publish!
    @published = true
    save
    trigger(:publish, Time.now)
    self
  end
end

a = Article.new("Ruby Metaprogramming")
a.save
# Article 'Ruby Metaprogramming' saved to database
# Cache invalidated for Ruby Metaprogramming

a.publish!
# Article 'Ruby Metaprogramming' saved to database
# Cache invalidated for Ruby Metaprogramming
# Email sent: 'Ruby Metaprogramming' is now live!
# Published at 2026-04-03 10:08:00 +0200
```

### Exercise 5

```ruby
# HTML DSL — html { head { title "Hello" }; body { p "World" } }
# Uses instance_eval to make the block run in the builder's context

class HtmlBuilder
  def initialize(tag, attrs = {})
    @tag      = tag
    @attrs    = attrs
    @children = []
  end

  def method_missing(tag, content = nil, **attrs, &block)
    child = HtmlBuilder.new(tag, attrs)
    if block
      child.instance_eval(&block)
    elsif content
      child << content.to_s
    end
    @children << child
    child
  end

  def respond_to_missing?(name, include_private = false)
    true
  end

  def <<(content)
    @children << content
    self
  end

  def render(indent = 0)
    spaces     = "  " * indent
    attr_str   = @attrs.map { |k, v| " #{k}=\"#{v}\"" }.join
    inner      = @children.map { |c| c.is_a?(String) ? "#{spaces}  #{c}" : c.render(indent + 1) }.join("\n")

    if inner.empty?
      "#{spaces}<#{@tag}#{attr_str}></#{@tag}>"
    else
      "#{spaces}<#{@tag}#{attr_str}>\n#{inner}\n#{spaces}</#{@tag}>"
    end
  end

  def to_s
    render
  end
end

def html(&block)
  builder = HtmlBuilder.new("html")
  builder.instance_eval(&block)
  "<!DOCTYPE html>\n#{builder.render}"
end

# Usage:
puts html {
  head {
    title "Hello, Ruby!"
    meta charset: "utf-8"
  }
  body {
    h1 "Welcome"
    p  "This HTML was generated by a Ruby DSL."
    div(class: "content") {
      p "Metaprogramming is powerful."
      p "instance_eval makes DSLs possible."
    }
  }
}

# <!DOCTYPE html>
# <html>
#   <head>
#     <title>
#       Hello, Ruby!
#     </title>
#     <meta charset="utf-8"></meta>
#   </head>
#   <body>
#     <h1>
#       Welcome
#     </h1>
#     ...
#   </body>
# </html>
```
