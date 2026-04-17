# Chapter 5 — Objects, Classes, Modules

The previous chapters mostly pushed data through methods. This chapter is where the data starts living inside objects. Objects are not a different universe. They are just a way to keep data and the methods that belong to that data together.

The three programs matter more than the terminology: an address book, an animal shelter, and a plugin loader. Each one answers the same question in a different way: what should one object remember, what behavior should be shared, and what behavior should be inherited?

Read the chapter in that order. First look at the object each program is built around. Then look at what that object needs to remember. Only after that worry about `attr_accessor`, `include`, or `super`. If the vocabulary starts stacking up, return to the programs. The programs carry the chapter.

## New Ruby ideas you'll meet in this chapter

- **Class** — a blueprint for objects. `Dog.new("Rex")` creates one. Each object has its own copy of the data (`@ivars`) but shares the methods.
- **`initialize`** — the special method called the moment a new object is born. This is where you stash the starting data in `@variables`.
- **Instance variable `@name`** — data that belongs to one object and sticks around for its lifetime.
- **`attr_reader` / `attr_writer` / `attr_accessor`** — macros that generate getter and/or setter methods so you don't write boilerplate.
- **Inheritance (`class Dog < Animal`)** — Dog gets every method Animal defines. `super` calls the parent's version of the same method.
- **Module** — a bag of methods you can mix into a class with `include` (instance methods) or `extend` (class / singleton methods). The Ruby substitute for multiple inheritance.
- **`Enumerable` mixin** — implement `each` on your class, `include Enumerable`, and get `map`, `select`, `group_by`, `count`, and many more for free.
- **`Data.define(:field1, :field2)`** — one-line immutable value object. Like Struct but the fields are read-only — safer by default.
- **`self`** — "the current object". Inside an instance method it's that instance; at the class level it's the class itself.

## Defining a class

```ruby
class Person
  def initialize(name, age)
    @name = name
    @age  = age
  end

  def greet
    "Hi, I'm #{@name}."
  end
end

p = Person.new("Yosia", 30)
puts p.greet   # => Hi, I'm Yosia.
```

`class Foo ... end` defines a class. `Foo.new(args)` creates an instance and calls `initialize(args)`. `@name` is an *instance variable* — each `Person` object has its own `@name`. Other objects can't see it directly.

## attr_reader, attr_writer, attr_accessor

Writing getters and setters by hand is tedious:

```ruby
class Person
  def name
    @name
  end

  def name=(value)
    @name = value
  end
end
```

Ruby has a class-method shortcut:

```ruby
class Person
  attr_accessor :name        # both reader and writer
  attr_reader   :id          # reader only (no setter)
  attr_writer   :secret      # writer only (rare)

  def initialize(name)
    @name = name
    @id   = name.downcase
  end
end
```

`attr_accessor :name` generates `name` and `name=` methods. `attr_reader :id` generates only `id`. The methods read and write the matching `@id` instance variable.

By Chapter 6 you'll know how to write `attr_accessor` yourself with `define_method`.

## self

Inside an instance method, `self` is the current object — the receiver of the method call.

```ruby
class Counter
  def initialize
    @value = 0
  end

  def increment
    @value += 1
    self           # return self for chaining
  end
end

c = Counter.new
c.increment.increment.increment   # method chaining works because each call returns self
```

`self.method` calls the method on the current object. You usually omit `self.` for *getters* (`@value` works) but you need it for *setters*:

```ruby
class Counter
  attr_accessor :value

  def reset_to(n)
    value = n            # WRONG — creates a local variable
    self.value = n       # right — calls the setter
  end
end
```

The `value = n` syntax always means "create a local variable" unless prefixed with `self.`. This is the most common Ruby gotcha for newcomers.

## Class methods

A class method belongs to the class itself, not to instances:

```ruby
class Person
  def self.from_string(s)
    name, age = s.split(",")
    Person.new(name, age.to_i)
  end
end

p = Person.from_string("Yosia,30")
```

`def self.method_name` defines a class method. The `self` inside the class definition refers to the class itself.

`from_*` methods are a Ruby idiom for alternate constructors — `Person.from_json`, `Person.from_csv`, etc.

## Method visibility

```ruby
class BankAccount
  attr_reader :balance

  def initialize
    @balance = 0
  end

  def deposit(amount)
    record(:deposit, amount)   # OK — private method called inside the class
    @balance += amount
  end

  private

  def record(type, amount)
    @history ||= []
    @history << [type, amount, Time.now]
  end
end

acct = BankAccount.new
acct.deposit(100)            # works
acct.record(:test, 50)       # raises NoMethodError: private method
```

`private` makes everything below it private — only callable from within the same object.

`protected` is rarely useful — same as private but allows other instances of the same class to call. Use `private` by default; reach for `protected` only when you have a reason.

## inspect, to_s

`puts obj` calls `obj.to_s`. `p obj` calls `obj.inspect`. The defaults are not great:

```ruby
class Person
  def initialize(name)
    @name = name
  end
end

puts Person.new("Yosia")   # => #<Person:0x000000010d839058>
p   Person.new("Yosia")    # => #<Person:0x000000010d839058 @name="Yosia">
```

Override `to_s` for the human-friendly form, `inspect` for the developer-friendly form:

```ruby
class Person
  attr_reader :name

  def initialize(name) = @name = name
  def to_s             = "Person(#{@name})"
  def inspect          = "#<Person name=#{@name.inspect}>"
end

puts Person.new("Yosia")  # => Person(Yosia)
p   Person.new("Yosia")   # => #<Person name="Yosia">
```

Use endless methods (Chapter 4) for simple one-line definitions.

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
  def speak = "#{@name}: woof!"
end

class Cat < Animal
  def speak = "#{@name}: meow."
end

dog = Dog.new("Rex")
puts dog            # => Dog(Rex)
puts dog.speak      # => Rex: woof!
```

`class Child < Parent` makes `Child` inherit from `Parent`. The child gets all the parent's methods; it can override any of them.

`super` calls the parent's method of the same name:

```ruby
class GuideDog < Dog
  def initialize(name, owner)
    super(name)         # call Dog#initialize (which calls Animal#initialize)
    @owner = owner
  end

  def speak
    super + " (guiding #{@owner})"
  end
end
```

`super` with no parens passes the same arguments. `super(...)` passes whatever you give it. `super()` passes nothing.

## Modules — methods you can mix in

A module is a collection of methods you can attach to any class via `include`:

```ruby
module Greetable
  def greet
    "Hello, I'm #{name}"     # assumes the class provides a `name` method
  end
end

class Dog
  include Greetable
  attr_reader :name
  def initialize(name) = @name = name
end

class Person
  include Greetable
  attr_reader :name
  def initialize(name) = @name = name
end

Dog.new("Rex").greet     # => Hello, I'm Rex
Person.new("Yosia").greet # => Hello, I'm Yosia
```

This is *mixin-style composition*. Inheritance gives you exactly one parent; modules let you compose behavior from many sources without forcing a hierarchy.

`include` makes module methods *instance methods*. `extend` makes them *class methods*:

```ruby
module Loggable
  def log(message) = puts "[#{Time.now}] #{message}"
end

class Service
  extend Loggable
end

Service.log("starting")   # => [2026-04-17 ...] starting
```

There's also `prepend`, which inserts the module *before* the class in the lookup order. Useful when you want the module's methods to wrap (and call `super` to delegate to) the class's methods.

## Comparable

The `Comparable` module gives you `<`, `<=`, `==`, `>=`, `>`, `between?`, `clamp` for free — define `<=>` (the "spaceship operator") and Ruby derives the rest:

```ruby
class Temperature
  include Comparable
  attr_reader :degrees

  def initialize(degrees) = @degrees = degrees.to_f
  def <=>(other)            = degrees <=> other.degrees
end

t1 = Temperature.new(72)
t2 = Temperature.new(85)

t1 < t2                                 # => true
[t1, t2].min                            # => Temperature(72)
t1.between?(Temperature.new(50), t2)    # => true
```

`a <=> b` returns `-1` if `a < b`, `0` if equal, `1` if `a > b`. Define it once; get the rest.

## Enumerable

The same trick scales up. The `Enumerable` module gives you `map`, `select`, `reject`, `each_with_index`, `tally`, `sort`, etc. — define `each` and you get all the rest:

```ruby
class TodoList
  include Enumerable

  def initialize
    @items = []
  end

  def add(item)
    @items << item
    self
  end

  def each(&block) = @items.each(&block)
end

list = TodoList.new
list.add("buy milk").add("clean room").add("study Ruby")
list.count                       # => 3
list.map(&:length)               # => [8, 11, 11]
list.select { |s| s.start_with?("c") }   # => ["clean room"]
list.sort                        # => sorted alphabetically
```

This is one of the highest-leverage features in Ruby. Define one method; get a buffet.

## Data — immutable value objects

For value objects (small types whose identity is "the data they hold"), use `Data.define`:

```ruby
Point = Data.define(:x, :y)

p1 = Point.new(3, 4)
p1.x          # => 3
p1.y          # => 4
p1 == Point.new(3, 4)   # => true   (value equality, not identity)
p1.x = 5      # raises NoMethodError — Data is frozen / immutable
```

Equality is by value. Instances are immutable. You can't accidentally mutate a `Point` after creating it.

For mutable lightweight types, use `Struct`:

```ruby
Account = Struct.new(:owner, :balance)
a = Account.new("yosia", 100)
a.balance += 10              # works — Struct is mutable
```

When in doubt, prefer `Data` (immutable). Reach for `Struct` only when mutability is what you actually want.

## Composition over inheritance

Three shapes for "a thing with behavior," in the order you should reach for them:

- **`Data.define`** — the thing *is* its data. No mutable state, no inheritance, equality by value. `Point`, `Money`, `Coordinate`. Start here whenever the type is mostly fields.
- **A class with included modules** — the thing has identity and changes over time, and its behavior is a *combination* of capabilities. `Shelter include Enumerable`. `User include Greetable, Loggable`. Modules let you mix in exactly the behavior you need, from many sources, without forcing a tree.
- **`class Child < Parent`** — only when the child is genuinely a *kind of* the parent and shares almost all of its behavior, and you have at least two such children. `Dog < Animal`, `Cat < Animal` qualifies. `Manager < User` usually doesn't — there's one `User` and a manager has a *role*, not a different identity.

Heuristic: if you find yourself writing `class Foo < Bar` and Bar has only one subclass, delete the inheritance and put the shared methods in a module. If you find yourself writing `attr_accessor` on a class with no behavior, switch to `Data.define`. Inheritance is the strongest coupling Ruby offers — earn it.

Enough pieces. Put them to work.

## First build: addr.rb

An address book with two classes: `Person` (a value-ish object) and `AddressBook` (the collection).

```ruby
# addr.rb — a tiny address book
# Usage: ruby addr.rb add NAME EMAIL
#        ruby addr.rb list
#        ruby addr.rb find QUERY

require "json"

Person = Data.define(:name, :email)

class AddressBook
  include Enumerable

  STORE = File.join(__dir__, "addr.json")

  def initialize
    @people = load
  end

  def add(person)
    @people << person
    save
    person
  end

  def find(query)
    @people.select { |p| p.name.downcase.include?(query.downcase) }
  end

  def each(&block) = @people.each(&block)

  private

  def load
    return [] unless File.exist?(STORE)
    JSON.parse(File.read(STORE)).map { |h| Person.new(name: h["name"], email: h["email"]) }
  end

  def save
    File.write(STORE, JSON.pretty_generate(@people.map { |p| { name: p.name, email: p.email } }))
  end
end

book = AddressBook.new

case ARGV.shift
when "add"
  name, email = ARGV
  abort "usage: addr.rb add NAME EMAIL" unless name && email
  person = book.add(Person.new(name: name, email: email))
  puts "added: #{person.name} <#{person.email}>"
when "list"
  book.each { |p| puts "#{p.name}  #{p.email}" }
when "find"
  query = ARGV.first or abort "usage: addr.rb find QUERY"
  matches = book.find(query)
  matches.each { |p| puts "#{p.name}  #{p.email}" }
  puts "no matches" if matches.empty?
else
  abort "usage: addr.rb (add|list|find) ARGS..."
end
```

What's new.

`Data.define(:name, :email)` creates a tiny immutable class with a constructor `Person.new(name:, email:)`, getters `.name` and `.email`, and value equality.

`include Enumerable` plus the `each` method gives `AddressBook` `count`, `map`, `select`, etc. for free.

`File.join(__dir__, "addr.json")` builds the path to a JSON file next to this script. `__dir__` is the directory of the file the code is in.

`save` rewrites the entire file every change. For a small address book, that's fine. For a larger one, you'd add an index or a real database.

(File: `examples/addr.rb`. Storage file is created at `examples/addr.json` on first run.)

## Second build: shelter.rb

An animal shelter with a hierarchy: `Dog`, `Cat`, `Bird` all inherit from `Animal`.

```ruby
# shelter.rb — animal shelter with class hierarchy
# Usage: ruby shelter.rb (demo)

class Animal
  attr_reader :name, :age

  def initialize(name, age)
    @name = name
    @age  = age
  end

  def speak
    raise NotImplementedError, "#{self.class} must implement speak"
  end

  def description = "#{self.class.name}(#{@name}, age #{@age})"
end

class Dog < Animal
  def speak = "#{@name}: woof!"
end

class Cat < Animal
  def speak = "#{@name}: meow."
end

class Bird < Animal
  def initialize(name, age, can_fly: true)
    super(name, age)
    @can_fly = can_fly
  end

  def speak = "#{@name}: tweet!"

  def description
    super + (@can_fly ? " (can fly)" : " (can't fly)")
  end
end

class Shelter
  include Enumerable

  def initialize
    @animals = []
  end

  def admit(animal)
    @animals << animal
    self
  end

  def each(&block) = @animals.each(&block)

  def by_species = group_by { |a| a.class.name }
end

if __FILE__ == $PROGRAM_NAME
  shelter = Shelter.new
  shelter.admit(Dog.new("Rex", 3))
         .admit(Cat.new("Whiskers", 5))
         .admit(Dog.new("Buddy", 1))
         .admit(Bird.new("Tweety", 2, can_fly: false))

  shelter.each { |a| puts a.description }
  puts
  shelter.by_species.each do |species, animals|
    puts "#{species}: #{animals.length}"
  end
end
```

What's new.

`raise NotImplementedError` in `Animal#speak` says "subclasses must implement this." Calling `Animal.new(...).speak` blows up — but you wouldn't normally instantiate `Animal` directly.

`Bird` adds `can_fly:` and overrides `description` to append flight status. `super` in `description` calls `Animal#description` and appends to the result.

`Shelter` `include Enumerable` and defines `each`. That alone gives it `group_by`, used in `by_species`.

(File: `examples/shelter.rb`.)

## Third build: plugins.rb

A plugin loader: drop a `.rb` file in `plugins/`, it gets loaded and registered. Each plugin is a module that gets mixed into a host class.

```ruby
# plugins.rb — a tiny plugin system
# Usage: ruby plugins.rb (demo, loads from examples/plugins/)

class Host
  def initialize
    @plugins = []
  end

  def install(plugin_module)
    extend(plugin_module)
    @plugins << plugin_module
    self
  end

  def list_plugins = @plugins.map(&:name)
end

if __FILE__ == $PROGRAM_NAME
  Dir[File.join(__dir__, "plugins", "*.rb")].each { |f| require f }

  host = Host.new
  host.install(Greeter).install(Counter)

  puts host.list_plugins
  puts host.greet("Yosia")
  puts host.tick
  puts host.tick
end
```

The plugin files (one per file under `examples/plugins/`):

```ruby
# examples/plugins/greeter.rb
module Greeter
  def greet(name) = "Hello, #{name}!"
end
```

```ruby
# examples/plugins/counter.rb
module Counter
  def tick
    @count ||= 0
    @count += 1
  end
end
```

Run:

```
$ ruby plugins.rb
Greeter
Counter
Hello, Yosia!
1
2
```

What's new.

`Dir[pattern]` returns matching paths. `Dir["plugins/*.rb"]` finds every `.rb` file in `plugins/`.

`require path` loads each matching file. Definitions in that file, like `module Greeter`, become available immediately after.

`extend(module)` mixes the module's methods into a single object — not the whole class. `host.extend(Greeter)` adds `greet` to `host` only, not to other `Host` instances.

This is the pattern Rails uses for *concerns*. It's the basis for almost every plugin system in Ruby.

(Files: `examples/plugins.rb`, `examples/plugins/greeter.rb`, `examples/plugins/counter.rb`.)

## One quick look at method lookup

Three things every Ruby object knows:

- **Its class:** `obj.class` — the class that built it
- **Its ancestors:** `obj.class.ancestors` — the lookup chain for method calls
- **Its singleton class:** `obj.singleton_class` — a per-object class that holds methods unique to this one object

```ruby
class Dog; end
class Puppy < Dog; end
module Loud; end
class Yapper < Puppy; include Loud; end

Yapper.ancestors
# => [Yapper, Loud, Puppy, Dog, Object, Kernel, BasicObject]
```

When you call `obj.foo`, Ruby walks the ancestors list left-to-right and runs the first `foo` it finds. Modules added with `include` sit after the class in that chain. Modules added with `prepend` sit before the class, which is why they can wrap the class's own methods.

This is how `super` knows what to call. This is how Comparable's methods reach your `<=>`. Chapter 6 uses this directly.

## Common pitfalls

`value = n` inside a method creates a local variable. It does *not* call your `value=` setter, even if you have `attr_accessor :value`. Ruby resolves bare assignment as "make a local" before it considers method dispatch. To call the setter, write `self.value = n`. This bites every newcomer at least once.

`attr_accessor :name` is sugar for two methods — `def name; @name; end` and `def name=(v); @name = v; end`. Nothing more. Override either one freely; you don't lose the other. Use plain `def` when the getter or setter has any logic at all (validation, formatting, lazy loading).

`Comparable` requires `<=>`, not `==`. `<=>` returns `-1`, `0`, or `1`. Defining `==` alone gives you nothing from `Comparable`; `Comparable` derives `==` from your `<=>`. Conversely, `Hash` and `Set` lookups go through `eql?` and `hash`, not `<=>` — if you put your objects in a hash, define those two as well.

`super` has three forms and they are not interchangeable. `super` (no parens) passes the *same arguments* the current method received. `super()` (empty parens) passes *nothing*. `super(a, b)` passes exactly `a` and `b`. Forgetting the parens when you want to pass nothing is a common bug — bare `super` will quietly forward arguments the parent doesn't expect.

Mutating shared frozen-looking constants. `NAMES = ["Alice", "Bob"]` looks constant but the array is mutable; `NAMES << "Carol"` works and silently changes shared state. Freeze the value: `NAMES = ["Alice", "Bob"].freeze`. For nested structures, freeze each layer or use `Data.define`.

## What you learned

| Concept | Key point |
|---|---|
| `class Foo ... end` | define a class |
| `Foo.new(args)` | calls `initialize(args)` |
| `@var` | instance variable, scoped to one object |
| `attr_accessor` / `_reader` / `_writer` | generate getters/setters |
| `self` | the current object; required when calling setters |
| `def self.method` | class method (alternate constructors are a common use) |
| `private` | only callable inside the class |
| `to_s` / `inspect` | override for friendly output |
| `class Child < Parent` | inheritance |
| `super` / `super(args)` / `super()` | call parent's method |
| `include Module` | mix instance methods into the class |
| `extend Module` | mix methods into a single object or as class methods |
| `prepend Module` | mix in *before* the class (rare but useful) |
| `Comparable` + `<=>` | gives `<`, `>`, `==`, `between?`, `clamp` |
| `Enumerable` + `each` | gives `map`, `select`, `count`, `tally`, ... |
| `Data.define(:a, :b)` | immutable value object |
| `Struct.new(:a, :b)` | mutable lightweight value object |
| `obj.class.ancestors` | the method-lookup chain |
| `obj.singleton_class` | per-object class for unique methods |

## Going deeper

Read the source of `ActiveSupport::Concern` (it's about 60 lines). It is a thin wrapper around `included`, `class_methods`, and dependency tracking — the entire Rails "concerns" pattern is sugar over `Module#include`. After you read it, the `app/models/concerns/` folder in any Rails app stops being magic.

Take a friend's class hierarchy — anything more than two levels deep — and refactor it into modules plus a flatter class. Most deep hierarchies hide one or two cross-cutting capabilities (loggable, persistable, comparable) that compose better as mixins than as inheritance.

Read the Ruby docs on `Module#refine`, `Module#include`, and `Module#prepend` side by side. The three are the entire mixin toolkit; `prepend` is the one most Ruby programmers under-use, and refinements are the one they over-fear. Knowing when each applies is the difference between writing libraries and writing scripts.

## Exercises

1. **Vector**: build a 3D vector class with `+`, `-`, scalar `*`, `dot`, `magnitude`, `normalize`. Define `==` and `to_s`. Starter: `exercises/1_vector.rb`.

2. **Queue**: build a `MyQueue` class wrapping an array with `enqueue`, `dequeue`, `peek`, `empty?`, `size`, plus `<<` as alias for `enqueue`. Include `Enumerable`. Starter: `exercises/2_queue.rb`.

3. **BankAccount with freeze**: build a BankAccount with `deposit`, `withdraw`, `transfer_to`, an audit history, and a `freeze!`/`unfrozen?` mechanism that prevents mutations. Starter: `exercises/3_bank_account.rb`.

4. **Range with custom step**: build a `Stepper` class that includes `Enumerable` and yields `start`, `start + step`, `start + 2*step`, ..., up to (and including) `stop`. Default `step` is `1`. Starter: `exercises/4_stepper.rb`.

5. **Plugin: timestamper**: write a third plugin (`plugins/timestamper.rb`) that adds a method `timestamp` returning the current time as ISO 8601. Test it by adding it to the demo in `plugins.rb`. Starter: `exercises/5_timestamper.rb`.

6. **shelter `oldest_by_species`**: extend `Shelter` with a method that returns a hash mapping species name → oldest animal of that species. Starter: `exercises/6_oldest.rb`.
