# Chapter 6 — Metaprogramming

Metaprogramming is where Ruby can feel magical for the first time. It can also get slippery fast. This chapter keeps it concrete: one attribute generator, one flexible object, one routing DSL.

The reading rule here is simple. Do not treat any of these techniques as tricks to sprinkle everywhere. Read each one as an answer to a narrow problem: a family of methods, a family of attribute names, a family of route declarations. It is fine if the example makes sense before the mechanism does.

## New Ruby ideas you'll meet in this chapter

Metaprogramming terms are the densest vocabulary in the book. Skim this list first; each term is unpacked with a working example below.

- **Open classes / monkey patching** — any class in Ruby, including `String` and `Array`, can be reopened and added to. Powerful and dangerous: use it sparingly.
- **`send` / `public_send`** — call a method whose name you only know as a symbol or string. `public_send` refuses to call private methods (safer).
- **`define_method(name) { ... }`** — create a real, named instance method at runtime from a block. This is how `attr_accessor` is built.
- **`instance_variable_get` / `instance_variable_set`** — read and write `@ivars` when you only know the name as a string.
- **`method_missing`** — Ruby's "method not found" hook. Intercept unknown calls to build dynamic attributes, dynamic finders, or ghost methods.
- **`respond_to_missing?`** — must be overridden alongside `method_missing` so `obj.respond_to?(:foo)` tells the truth about your dynamic methods.
- **`class << self`** — opens the class's singleton class. Everything defined inside becomes a class-level method.
- **`class_eval(&block)` / `instance_eval(&block)`** — run a block with `self` switched to a class or an instance, so method calls inside the block resolve there.
- **`inherited(subclass)` hook** — fires automatically the moment a subclass is defined. Handy for giving each subclass its own class-level state.
- **DSL (Domain-Specific Language)** — a method API that reads like English (`get "/home" do ... end`). Usually built out of the other techniques above.

## Open classes

Every class in Ruby can be reopened at any point and added to:

```ruby
class String
  def shout = upcase + "!"
end

"hello".shout   # => "HELLO!"
```

This is **monkey patching**. Powerful and dangerous in equal measure: every String in your program gets `shout` now, including ones in libraries you didn't write. Rails uses monkey patches heavily but namespaces them through ActiveSupport. Outside Rails: monkey-patch core classes only when you have a good reason and leave a comment explaining why.

For safer scoped patches, see `refinements` later in this chapter.

## send and public_send

Call any method by name, with the name as a string or symbol:

```ruby
"hello".send(:upcase)      # => "HELLO"
"hello".send("upcase")     # => "HELLO"     (string works too)
[1, 2, 3].send(:[], 1)     # => 2

method = :upcase
"hello".send(method)       # => "HELLO"

# send bypasses private:
class Secret
  private
  def shh = "shhh"
end
Secret.new.send(:shh)         # => "shhh"      (works — private bypassed)
Secret.new.public_send(:shh)  # NoMethodError  (respects private)
```

Use `public_send` by default. Reach for `send` only when you genuinely need to bypass privacy. That is rare, and often a sign that a simpler design would read better.

## define_method

Inside a class definition, generate methods at the moment the class is loaded:

```ruby
class Color
  COLORS = %i[red green blue yellow]

  COLORS.each do |c|
    define_method("#{c}?") { @color == c }
    define_method("#{c}!") { @color = c }
  end

  def initialize(color = :red)
    @color = color
  end
end

c = Color.new
c.red?     # => true
c.blue!    # changes @color to :blue
c.blue?    # => true
```

`define_method(name) { ... }` creates an instance method named `name` whose body is the block. The methods exist forever after — they're real methods, not magic.

This is exactly how `attr_accessor` works. You can write your own:

```ruby
class Module
  def attr_logged(*names)
    names.each do |name|
      define_method(name)         { instance_variable_get("@#{name}") }
      define_method("#{name}=")   do |value|
        puts "set #{name} = #{value.inspect}"
        instance_variable_set("@#{name}", value)
      end
    end
  end
end

class Person
  attr_logged :name, :email
end

p = Person.new
p.name = "Yosia"     # prints: set name = "Yosia"
p.name               # => "Yosia"
```

`Module` is the parent of `Class`, so adding `attr_logged` there makes it available inside *every* class definition. That's exactly how the built-in `attr_accessor` is implemented.

`instance_variable_get`/`instance_variable_set` reach into an object's instance vars by name (string or symbol). The `@` is part of the name.

## method_missing and respond_to_missing?

When you call a method on an object and Ruby can't find it, before raising `NoMethodError`, Ruby calls `method_missing(name, *args, **kwargs, &block)`. Define that and you intercept anything:

```ruby
class FlexHash
  def initialize(data = {})
    @data = data
  end

  def method_missing(name, *args)
    name_str = name.to_s
    if name_str.end_with?("=")
      @data[name_str.chomp("=").to_sym] = args.first
    elsif @data.key?(name)
      @data[name]
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    @data.key?(name) || name.to_s.end_with?("=") || super
  end
end

h = FlexHash.new
h.user = "yosia"
h.role = "admin"
h.user        # => "yosia"
h.role        # => "admin"
h.respond_to?(:user)   # => true
```

Two rules worth being strict about:

1. **Always call `super` for cases you don't handle.** Otherwise you silently swallow real `NoMethodError`s — typos become `nil` returns and bugs hide for months.
2. **Always pair `method_missing` with `respond_to_missing?`.** Lots of Ruby code asks "do you respond to this?" before calling it. Without `respond_to_missing?`, your dynamic methods are invisible to introspection.

This is how ActiveRecord lets you write `User.find_by_email("x")` for any column.

## class_eval and instance_eval

`class_eval` runs a block in the *class*'s context — `self` is the class, and `def`s define instance methods:

```ruby
class Animal
end

Animal.class_eval do
  def speak = "noise!"
end

Animal.new.speak    # => "noise!"
```

`instance_eval` runs a block in an *object*'s context — `self` is the object, and `def`s define methods on its singleton class (just that one object):

```ruby
str = "hello"
str.instance_eval do
  def shout = upcase + "!"
end

str.shout         # => "HELLO!"
"hello".shout     # NoMethodError — only str got the method
```

These two are how DSLs work. `before { ... }` in RSpec, `routes.draw do ... end` in Rails — each one runs your block in a context where the methods you call (`before`, `get`, `resources`) are available because the framework set up `self` to provide them.

## Hooks

Ruby calls back into your code at key moments in class life:

```ruby
class Loggable
  def self.inherited(subclass)
    puts "#{subclass} now extends Loggable"
  end
end

class A < Loggable; end   # => A now extends Loggable
class B < Loggable; end   # => B now extends Loggable
```

The big four:

- `inherited(subclass)` — called when a class is subclassed
- `included(klass)` — called when a module is `include`d
- `extended(klass)` — called when a module is `extend`ed
- `method_added(method_name)` — called whenever a method is defined

These power most "auto-register yourself" patterns. Rails uses `inherited` to track every model. Sidekiq uses `included` to register every worker.

## prepend and the singleton class

`include` inserts a module into the lookup chain after the class. `prepend` inserts it before the class, so the module's methods run first and can delegate with `super`. That makes `prepend` useful for wrapping methods:

```ruby
module Timing
  def call(*args)
    started = Time.now
    result  = super        # call the wrapped method
    puts "#{(Time.now - started) * 1000}ms"
    result
  end
end

class Slow
  prepend Timing
  def call(n) = n.times.sum
end

Slow.new.call(1_000_000)   # prints timing, returns sum
```

The *singleton class* of an object is a hidden per-object class that holds methods unique to that one object. `def self.x` (inside a class) defines a method on the class's singleton class. `obj.singleton_class.define_method(:x) { ... }` adds a method to one specific object only.

## Refinements — scoped monkey patches

Refinements let you patch a class but only inside one specific scope:

```ruby
module Shouty
  refine String do
    def shout = upcase + "!"
  end
end

# Outside the refinement scope: no shout
"hello".shout rescue puts "not found"

# Inside the refinement scope: shout works
class Loud
  using Shouty

  def yell(text) = text.shout
end

Loud.new.yell("hello")    # => "HELLO!"
```

Refinements never leak. They're safer than monkey patching but harder to debug — you can read code that calls `.shout` and have to track down which `using` statement is in scope.

Use refinements when you need a focused change for one library or one file. For everything else, prefer well-named methods on objects you own.

Enough machinery. Build something with it.

## mini_attr.rb

Build your own attr_* family: `attr_logged` (logs reads/writes), `attr_typed` (rejects values of the wrong type), `attr_memoized` (caches the first computed value).

```ruby
# mini_attr.rb — your own attribute generators
module Attrs
  def attr_logged(*names)
    names.each do |name|
      define_method(name) { instance_variable_get("@#{name}") }
      define_method("#{name}=") do |value|
        puts "[set] #{self.class}##{name} = #{value.inspect}"
        instance_variable_set("@#{name}", value)
      end
    end
  end

  def attr_typed(name, type)
    define_method(name) { instance_variable_get("@#{name}") }
    define_method("#{name}=") do |value|
      raise TypeError, "#{name} expected #{type}, got #{value.class}" unless value.is_a?(type)
      instance_variable_set("@#{name}", value)
    end
  end

  def attr_memoized(name, &block)
    define_method(name) do
      ivar = "@#{name}"
      return instance_variable_get(ivar) if instance_variable_defined?(ivar)
      value = instance_eval(&block)
      instance_variable_set(ivar, value)
      value
    end
  end
end

class Class
  include Attrs
end

class User
  attr_logged :name
  attr_typed  :age, Integer
  attr_memoized(:expensive) {
    puts "[compute] expensive once"
    42
  }
end

u = User.new
u.name = "Yosia"            # logs the set
u.age  = 30                 # ok
# u.age = "thirty"          # would raise TypeError
puts u.expensive            # computes once
puts u.expensive            # cached
```

`include Attrs` into `Class` makes `attr_logged`, `attr_typed`, `attr_memoized` available inside *every* class definition — same trick as the built-in `attr_accessor`.

`instance_variable_get/_set` and `instance_variable_defined?` work with strings or symbols starting with `@`.

`instance_eval(&block)` runs the block with `self` set to the current instance — so the block can use other methods of the same object.

(File: `examples/mini_attr.rb`.)

## flex.rb

A FlexHash that responds to any method as a getter/setter for its data — the prototype of how `OpenStruct` and many config objects work.

```ruby
# flex.rb — flexible attribute object via method_missing
class Flex
  def initialize(data = {}) = @data = data.dup

  def to_h = @data.dup
  def [](key) = @data[key]
  def []=(key, value)
    @data[key] = value
  end

  def method_missing(name, *args)
    name_str = name.to_s
    if name_str.end_with?("=")
      @data[name_str.chomp("=").to_sym] = args.first
    elsif @data.key?(name)
      @data[name]
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    @data.key?(name) || name.to_s.end_with?("=") || super
  end
end

config = Flex.new(host: "localhost")
config.port = 8080
config.ssl  = true

puts config.host    # localhost
puts config.port    # 8080
puts config.ssl     # true

puts config.respond_to?(:host)    # true
puts config.respond_to?(:nope)    # false
```

Note: `def []=(key, value)` cannot use the endless-method form (`= ...`) — Ruby disallows endless setters because `def m=(v) = v` is ambiguous with assigning a value. Use the regular `def ... end` form for setters.

(File: `examples/flex.rb`.)

## mini_dsl.rb

A route-declaration DSL using `class_eval` and the `inherited` hook. This is a stripped-down version of how Rails routes work.

```ruby
# mini_dsl.rb — declarative routing DSL
class Router
  Route = Data.define(:method, :path, :handler)

  def self.routes = (@routes ||= [])

  def self.inherited(subclass)
    subclass.instance_variable_set(:@routes, [])
  end

  def self.draw(&block) = class_eval(&block)

  %i[get post put patch delete].each do |verb|
    define_singleton_method(verb) do |path, &handler|
      routes << Route.new(method: verb, path: path, handler: handler)
    end
  end

  def self.dispatch(method, path)
    route = routes.find { |r| r.method == method && r.path == path }
    return "404 not found" unless route
    route.handler.call
  end
end

class App < Router
  draw do
    get  "/"        do "home" end
    get  "/about"   do "about page" end
    post "/signup"  do "signed up!" end
  end
end

puts App.dispatch(:get,  "/")          # home
puts App.dispatch(:get,  "/about")     # about page
puts App.dispatch(:post, "/signup")    # signed up!
puts App.dispatch(:get,  "/missing")   # 404 not found
```

`define_singleton_method(name) { ... }` defines a method on the class itself (not on instances). We use it to generate `Router.get`, `Router.post`, etc. — five class methods from a loop.

`Router.inherited(subclass)` runs when someone does `class App < Router`. We give the subclass its own `@routes` array so `App` and `Router` don't share state.

`draw(&block)` accepts a block and runs it with `class_eval`, so inside the block, calls to `get` and `post` resolve against `App`'s own class-method table.

This is the same pattern Rails uses in `config/routes.rb`. The `Rails.application.routes.draw do ... end` block runs in a context where `resources`, `get`, `namespace`, etc. are defined.

(File: `examples/mini_dsl.rb`.)

## When NOT to use metaprogramming

Metaprogramming buys leverage and spends clarity. The trade is worth it less often than enthusiasts pretend. Three rules of thumb.

If deleting one `define_method` loop and writing three explicit methods would make the file shorter to read (not to type) — write the three. The reader does not benefit from your loop.

If a colleague would have to `grep` your codebase for `method_missing` to figure out where `user.full_name` is defined, the indirection has cost more than it saved. Explicit methods land in editor "go to definition." Dynamic ones do not.

If five lines of duplication would be more honest than three lines of magic, take the duplication. Duplication is visible; magic is invisible. Visible problems get fixed; invisible ones become legend.

The right time to reach for these tools is when there is a real *family* of things — a set of attributes, a list of HTTP verbs, columns coming from a database schema you do not own. A *family* of three with no growth on the horizon is not a family. It is three.

## Common pitfalls

- **`method_missing` without `super`.** Forget the `super` in the unhandled branch and every typo that should have been `NoMethodError` becomes a silent `nil`. Bugs hide for months. The `else super` branch is not optional.
- **`method_missing` without `respond_to_missing?`.** `obj.respond_to?(:foo)` returns `false` even when `obj.foo` works. Anything that introspects — serializers, form builders, RSpec matchers — sees a hole where your method should be. Always pair the two.
- **Reopening core classes globally.** Adding `String#shout` in one file changes every `String` everywhere, including in gems you did not write. The bug surfaces in a stack trace that has nothing to do with your file. Use a refinement, or put the helper on a class you own.
- **`class_eval` vs `instance_eval` confusion.** Inside `class_eval`, `self` is the class; `def foo` defines an *instance* method. Inside `instance_eval`, `self` is the object; `def foo` defines a method on its singleton class. Mix them up and you end up with class methods you wanted as instance methods, or vice versa. When in doubt, drop `puts self` into the block and re-read.
- **Generated method names colliding with existing methods.** `define_method(:hash)` silently replaces `Object#hash`, breaking every Hash that holds your object. Before generating, check `instance_methods(false)` and `Object.instance_methods` for clashes. Reserve a prefix (`field_`, `attr_`) when generating from user-supplied names.

## Debugging metaprogrammed code

Three tools find generated methods. `obj.method(:foo).source_location` returns the `[file, line]` where `foo` was defined — works for `define_method`-generated methods too. `Module#instance_methods(false)` lists methods defined directly on a class (no inherited noise), useful for confirming a generator actually ran. For deeper traces, `TracePoint.new(:call, :return) { |tp| puts tp.method_id }.enable { ... }` prints every method called inside the block — the modern replacement for `set_trace_func`.

## What you learned

| Concept | Key point |
|---|---|
| Open classes | reopen any class anywhere; add methods |
| `send` / `public_send` | call a method by name; bypass privacy or not |
| `define_method` | generate methods at class load time |
| `method_missing` + `respond_to_missing?` | intercept undefined calls |
| `instance_variable_get/_set` | reach into an object's `@vars` by name |
| `class_eval(&block)` | run the block as if you were inside the class def |
| `instance_eval(&block)` | run the block with `self` = an object |
| `inherited`, `included`, `extended`, `method_added` | hooks Ruby calls into |
| `prepend Module` | put the module *below* the class in lookup |
| `singleton_class` | a per-object class for unique methods |
| `using Module` (refinements) | scoped monkey patches that don't leak |
| `define_singleton_method` | add a method to one specific object/class |

## Going deeper

- Read the source of `ActiveRecord::DynamicMatchers` and `ActiveRecord::AttributeMethods` in the Rails repo. `find_by_email` and the per-column readers are exactly the patterns in this chapter, in production. Skim — do not try to understand all of it.
- Read *Metaprogramming Ruby 2* by Paolo Perrotta. It is the book on this topic. The "object model" chapter alone repays the price.
- Pick one metaprogrammed gem you already use (ActiveRecord, RSpec, Sinatra). Drop a `binding.irb` into one of its dynamic methods, run your test, and walk through what `self`, `caller`, and `instance_variables` look like at that point. Real metaprogramming is easier to read than to imagine.

## Exercises

1. **attr_validated**: add `attr_validated(name, &block)` to `mini_attr.rb` — accepts a value only if the block returns truthy. `attr_validated(:age) { |v| v.is_a?(Integer) && v >= 0 }`. Starter: `exercises/1_attr_validated.rb`.

2. **Counter via method_missing**: build a `Counter` where `c.foo` returns 0, then `c.foo!` increments it and returns the new value. Any method name is a counter key. Use method_missing. Starter: `exercises/2_counter.rb`.

3. **Mass-assignment helper**: write a module `MassAssign` that, when included, gives the host class an `assign(hash)` method that calls each setter. Hint: iterate the hash, build setter names, use `public_send`. Starter: `exercises/3_mass_assign.rb`.

4. **Auto-registry**: write a module `Registerable` such that any class that includes it appears in `Registerable.classes`. Use the `included` hook. Starter: `exercises/4_registerable.rb`.

5. **Lazy attr_memoized**: extend `attr_memoized` so the cached value is per-object (already is) AND can be reset with `clear_<name>` (e.g., `obj.clear_expensive` removes the cache, next call recomputes). Starter: `exercises/5_attr_memoized_clear.rb`.

6. **DSL with parameters**: extend `mini_dsl.rb` so routes can have `:param`-style placeholders (e.g., `get "/users/:id"`). The handler block should receive a hash of the captured params. Starter: `exercises/6_router_params.rb`.
