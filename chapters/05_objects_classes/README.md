# Chapter 5 — Objects, Classes, Modules

So far your programs have pushed data through methods. Now the data starts living inside objects. An object is a small bag of data (`@variables`) plus the methods that belong to that data.

The chapter builds three programs: an address book, an animal shelter, and a plugin loader. Each one asks a different question. What should one object *remember*? What behavior should be *shared*? What behavior should be *inherited* — or mixed in? We answer each question by building the program.

Read in order. Don't skim for vocabulary.

## First build: addr.rb

A tiny address book. You add people, list them, or search by name. The data lives in a JSON file next to the script so it survives between runs.

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

Run it:

```
$ ruby addr.rb add Yosia yosia@example.com
added: Yosia <yosia@example.com>
$ ruby addr.rb add Alice alice@example.com
added: Alice <alice@example.com>
$ ruby addr.rb list
Yosia  yosia@example.com
Alice  alice@example.com
$ ruby addr.rb find ali
Alice  alice@example.com
```

Six new things.

### `Data.define` — a value object in one line

```ruby
Person = Data.define(:name, :email)

p = Person.new(name: "Yosia", email: "yosia@example.com")
p.name    # => "Yosia"
p.email   # => "yosia@example.com"
p == Person.new(name: "Yosia", email: "yosia@example.com")  # => true
p.name = "Someone"   # NoMethodError — Data is immutable
```

`Data.define(:name, :email)` builds a small class with read-only accessors, a keyword-argument constructor, and value equality. When an object *is* its data — a person, a point, a piece of money — reach for `Data` first. You'll use it constantly.

### `class` and `initialize`

```ruby
class AddressBook
  def initialize
    @people = load
  end
end

book = AddressBook.new
```

`class X ... end` defines a class. `X.new(args)` creates an instance and immediately calls `initialize(args)`. Inside an instance method, `@people` is an *instance variable* — data that belongs to this one object and survives between method calls. Other objects can't see it directly.

### `include Enumerable` + `each`

```ruby
class AddressBook
  include Enumerable
  def each(&block) = @people.each(&block)
end

book.count                          # works
book.select { |p| p.name == "Yo" }  # works
book.map(&:email)                   # works
```

This is one of Ruby's highest-leverage tricks. Implement `each` on your class, mix in the `Enumerable` module, and you get `count`, `map`, `select`, `reject`, `group_by`, `sort_by`, `tally`, and dozens more — for free. `find` inside `AddressBook` uses `select` for exactly this reason.

`&block` captures whatever block the caller passed, and `@people.each(&block)` forwards it along. Chapter 4 introduced the `&` prefix.

### `STORE` — a constant

```ruby
STORE = File.join(__dir__, "addr.json")
```

Uppercase names are constants. `__dir__` is the directory the current source file lives in. `File.join(__dir__, "addr.json")` builds a path to a JSON file sitting next to the script, regardless of where the user runs `ruby addr.rb` from.

### `private`

```ruby
class AddressBook
  def add(person) ... end    # public

  private

  def load ... end           # private
  def save ... end           # private
end
```

Everything after `private` is callable only from inside the class. `book.save` from outside raises `NoMethodError`. The point isn't secrecy; it's shape. Callers see `add` and `find`. They don't see (or touch) the JSON-file machinery. That split is what lets you change `save` to use a database later without breaking anything that uses the book.

### The `case` dispatcher at the bottom

```ruby
case ARGV.shift
when "add"  then ...
when "list" then ...
when "find" then ...
else abort "usage: ..."
end
```

`ARGV.shift` removes and returns the first command-line word (the subcommand). `case` routes to the right branch. You built `calc.rb` with the same shape in Chapter 1.

(File: `examples/addr.rb`. JSON file is created at `examples/addr.json` on the first `add`.)

## Second build: shelter.rb

An animal shelter. Dogs, cats, and birds all have a name and an age. They all speak, but each one speaks differently. A Bird also knows whether it can fly.

That description is the shape of the code.

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

Run it:

```
$ ruby shelter.rb
Dog(Rex, age 3)
Cat(Whiskers, age 5)
Dog(Buddy, age 1)
Bird(Tweety, age 2) (can't fly)

Dog: 2
Cat: 1
Bird: 1
```

Four new things.

### `attr_reader`

```ruby
class Animal
  attr_reader :name, :age
  def initialize(name, age)
    @name = name
    @age  = age
  end
end
```

`attr_reader :name, :age` is a shorthand for two getter methods:

```ruby
def name; @name; end
def age;  @age;  end
```

Nothing more. `attr_accessor` is the read/write version (you'll see it later). `attr_writer` generates only the setter. Use `attr_reader` when the outside world can read but shouldn't set; use `attr_accessor` when both should be open. Use plain `def` the moment the accessor has any logic at all.

### `class Dog < Animal` — inheritance

```ruby
class Animal
  def description = "#{self.class.name}(#{@name}, age #{@age})"
end

class Dog < Animal
  def speak = "#{@name}: woof!"
end

Dog.new("Rex", 3).description   # => "Dog(Rex, age 3)"  — inherited from Animal
Dog.new("Rex", 3).speak         # => "Rex: woof!"       — defined on Dog
```

`<` makes `Dog` inherit from `Animal`. `Dog` gets everything `Animal` defined — `name`, `age`, `description` — and can add or override methods. `self.class` is the object's own class; `self.class.name` is its class name as a string, which is why `Dog.new(...).description` prints `"Dog(...)"` not `"Animal(...)"`.

`NotImplementedError` inside `Animal#speak` marks it as an *abstract* method: subclasses must supply a real one. Instantiating `Animal` directly and calling `speak` blows up. That's usually what you want.

### `super`

```ruby
class Bird < Animal
  def initialize(name, age, can_fly: true)
    super(name, age)            # call Animal#initialize(name, age)
    @can_fly = can_fly
  end

  def description
    super + (@can_fly ? " (can fly)" : " (can't fly)")
  end
end
```

`super` calls the parent's method of the same name. Three forms, not interchangeable:

- `super` (no parens) — pass the *same arguments* this method received.
- `super()` (empty parens) — pass *nothing*.
- `super(a, b)` — pass exactly `a` and `b`.

`Bird#initialize` has to write `super(name, age)` because `Animal#initialize` doesn't accept the `can_fly:` keyword. `Bird#description` uses bare `super` because it takes no arguments and we want to forward nothing.

### `include Enumerable` again

`Shelter` does the same `include Enumerable` + `each` trick as `AddressBook`. That's the reason `by_species` can call `group_by` out of thin air — `group_by` is one of the methods Enumerable gave us.

`admit` returns `self` so calls can be chained: `shelter.admit(...).admit(...)`. A tiny habit that makes setup code read clearly.

(File: `examples/shelter.rb`.)

## Third build: plugins.rb

A plugin loader. Drop a `.rb` file into a `plugins/` folder, and the program loads it and mixes its methods into one host object. That's the core pattern Rails uses for *concerns*, and it's the basis for most Ruby plugin systems.

```ruby
# plugins.rb — a tiny plugin system
# Usage: ruby plugins.rb (loads from examples/plugins/)

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

And the plugins themselves, one per file under `plugins/`:

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

Run it:

```
$ ruby plugins.rb
Greeter
Counter
Hello, Yosia!
1
2
```

Three new things.

### `module` — a bag of methods

```ruby
module Greeter
  def greet(name) = "Hello, #{name}!"
end
```

A module is a named collection of methods. It isn't a class — you can't `Greeter.new`. Modules exist to be mixed into classes (with `include`) or into individual objects (with `extend`). Ruby's answer to "we don't have multiple inheritance": mix as many modules in as you need.

### `extend` vs `include`

```ruby
class Host
  def install(plugin_module)
    extend(plugin_module)   # mix into THIS object only
    @plugins << plugin_module
    self
  end
end
```

- `include Greeter` (inside a class) — every instance of the class gets `greet`.
- `extend Greeter` (on an object) — only *this* object gets `greet`.

The plugin loader uses `extend` because different hosts should be able to install different sets of plugins. Mixing into the class itself would give every host the same behavior. (`extend` also works at the class level, where it mixes *class* methods instead — we'll meet that in Chapter 6.)

### `Dir[pattern]` + `require`

```ruby
Dir[File.join(__dir__, "plugins", "*.rb")].each { |f| require f }
```

`Dir[pattern]` returns every path matching a glob. `"plugins/*.rb"` finds every `.rb` file one level inside `plugins/`. `require path` loads the file — its definitions become available immediately. That's the whole plugin auto-discovery mechanism, in one line.

This pattern shows up again: Rails initializers, test suites, Rack middleware stacks. Once you see it here, you'll recognise it everywhere.

(Files: `examples/plugins.rb`, `examples/plugins/greeter.rb`, `examples/plugins/counter.rb`.)

## More tools you'll need

The three programs introduced the essentials. The rest of the object system comes up often enough that you should know the shape before Chapter 6.

### `attr_accessor` and `attr_writer`

```ruby
class Account
  attr_reader   :id        # id getter only
  attr_writer   :secret    # secret= setter only  (rare)
  attr_accessor :balance   # balance AND balance=
end
```

Default to `attr_reader`. Upgrade to `attr_accessor` only when the outside actually needs to set. Leave raw `def name; @name; end` for whenever you want to do anything at all inside the getter — compute, cache, log.

### `self`

Inside an instance method, `self` is the current object.

```ruby
class Counter
  attr_accessor :value

  def initialize
    @value = 0
  end

  def increment
    @value += 1
    self                 # return self so we can chain
  end

  def reset_to(n)
    value = n            # WRONG — creates a local variable
    self.value = n       # right — calls the value= setter
  end
end
```

The second gotcha in `reset_to` is the single most common Ruby stumble. `x = v` always creates a local variable unless you write `self.x = v`. Ruby resolves `=` as *assignment* before it considers method dispatch.

### Class methods

```ruby
class Person
  def self.from_string(s)
    name, age = s.split(",")
    Person.new(name, age.to_i)
  end
end

Person.from_string("Yosia,30")
```

`def self.method_name` defines a method on the class itself, not on instances. `from_*` methods are the Ruby idiom for alternate constructors: `Person.from_json`, `Post.from_csv`, and so on.

### `to_s` and `inspect`

```ruby
class Person
  def initialize(name) = @name = name
  def to_s             = "Person(#{@name})"
  def inspect          = "#<Person name=#{@name.inspect}>"
end

puts Person.new("Yosia")   # => Person(Yosia)        via to_s
p    Person.new("Yosia")   # => #<Person name="Yosia">  via inspect
```

`puts` calls `to_s`. `p` calls `inspect`. Override both when the defaults (`#<Person:0x0001...>`) get in your way.

### `Comparable` + `<=>`

`Enumerable` gave you every iteration method from one `each`. `Comparable` does the same trick for ordering: define `<=>` and you get `<`, `<=`, `==`, `>=`, `>`, `between?`, and `clamp`.

```ruby
class Temperature
  include Comparable
  attr_reader :degrees

  def initialize(degrees) = @degrees = degrees.to_f
  def <=>(other)          = degrees <=> other.degrees
end

Temperature.new(72) < Temperature.new(85)   # => true
[Temperature.new(85), Temperature.new(72)].min
```

`a <=> b` returns `-1`, `0`, or `1`. Define one method; get the rest.

### `prepend`

`include Mod` inserts `Mod` *after* the class in the method-lookup chain. `prepend Mod` inserts it *before*, which means the module's methods can wrap the class's methods and call `super` to delegate. Useful for instrumentation and Active Support patches. Rare in day-to-day code.

### `Struct` — like `Data` but mutable

```ruby
Account = Struct.new(:owner, :balance)
a = Account.new("yosia", 100)
a.balance += 10     # works — Struct is mutable
```

`Data.define` is the default. Reach for `Struct` only when mutability is actually what you want.

### The lookup chain

```ruby
class Dog; end
class Puppy < Dog; end
module Loud; end
class Yapper < Puppy; include Loud; end

Yapper.ancestors
# => [Yapper, Loud, Puppy, Dog, Object, Kernel, BasicObject]
```

When you call `obj.foo`, Ruby walks the ancestors list left-to-right and runs the first matching `foo`. `include` puts modules after the class; `prepend` puts them before. `super` walks to the *next* ancestor. That's the whole lookup rule — every other dispatch trick (Chapter 6) is built on it.

### When to use what

Three shapes for "a thing with behavior", in the order you should reach for them:

1. **`Data.define`** — the thing *is* its data. No mutable state, no inheritance, equality by value. `Point`, `Money`, `Person`. Start here.
2. **A class with included modules** — the thing has identity, changes over time, and its behavior is a combination of capabilities (`Shelter include Enumerable`). Modules let you compose from many sources.
3. **`class Child < Parent`** — only when the child is genuinely a *kind of* the parent, shares almost all of its behavior, and you have at least two such children. `Dog < Animal` qualifies. `Manager < User` usually doesn't.

Inheritance is the strongest coupling Ruby offers. Earn it.

## Common pitfalls

- **`value = n` doesn't call your setter.** Write `self.value = n`. This bites every newcomer at least once.
- **Bare `super` forwards every argument.** Write `super()` when you want to pass nothing, `super(a)` when you want to pass exactly one thing. The difference is silent — `Bird.new("Rex", 3, can_fly: false)` with bare `super` in `initialize` will try to pass `can_fly:` to `Animal#initialize`, which doesn't accept it.
- **`Comparable` derives `==` from your `<=>`.** Defining `==` alone gives you nothing from Comparable. But `Hash` and `Set` lookups use `eql?` and `hash`, not `<=>` — if you put objects in a hash, define those two as well.
- **Constants aren't frozen.** `NAMES = ["Alice", "Bob"]` can still be mutated: `NAMES << "Carol"` works and silently shares state. Write `NAMES = ["Alice", "Bob"].freeze`.
- **Private methods have limits.** `private` blocks `obj.foo` from outside, but `obj.send(:foo)` bypasses it. If you need hard privacy, you don't have it in Ruby.

## What you learned

| Concept | Key point |
|---|---|
| `class Foo ... end` | define a class |
| `Foo.new(args)` | calls `initialize(args)` |
| `@var` | instance variable, scoped to one object |
| `attr_reader` / `_writer` / `_accessor` | generate getters / setters |
| `self` | the current object; required when calling setters |
| `def self.method` | class method (alternate constructors, etc.) |
| `private` | callable only from inside the class |
| `to_s` / `inspect` | override for friendly output |
| `class Child < Parent` | inheritance |
| `super` / `super()` / `super(args)` | call parent's method; three forms are not the same |
| `include Module` | mix instance methods into a class |
| `extend Module` | mix methods into one object |
| `prepend Module` | mix before the class in the lookup chain |
| `Enumerable` + `each` | gives `map`, `select`, `group_by`, `tally`, ... |
| `Comparable` + `<=>` | gives `<`, `>`, `==`, `between?`, `clamp` |
| `Data.define(:a, :b)` | immutable value object |
| `Struct.new(:a, :b)` | mutable lightweight value object |
| `obj.class.ancestors` | the method-lookup chain |

## Going deeper

Read the source of `ActiveSupport::Concern` — about sixty lines. It's a thin wrapper around `included`, `class_methods`, and dependency tracking. The entire Rails "concerns" pattern is sugar over `Module#include`. After you read it, `app/models/concerns/` stops being magic.

Take a class hierarchy three levels deep and refactor it into modules plus a flatter class. Most deep hierarchies hide one or two cross-cutting capabilities (loggable, persistable, comparable) that compose better as mixins than as inheritance.

Read the Ruby docs on `Module#refine`, `Module#include`, and `Module#prepend` side by side. Knowing when each applies is the difference between writing libraries and writing scripts.

## Exercises

1. **Vector**: a 3D vector class with `+`, `-`, scalar `*`, `dot`, `magnitude`, `normalize`. Define `==` and `to_s`. Starter: `exercises/1_vector.rb`.

2. **Queue**: a `MyQueue` class wrapping an array with `enqueue`, `dequeue`, `peek`, `empty?`, `size`, plus `<<` as alias for `enqueue`. Include `Enumerable`. Starter: `exercises/2_queue.rb`.

3. **BankAccount with freeze**: `deposit`, `withdraw`, `transfer_to`, an audit history, and a `freeze!`/`unfrozen?` mechanism that prevents mutations once frozen. Starter: `exercises/3_bank_account.rb`.

4. **Range with custom step**: a `Stepper` class that includes `Enumerable` and yields `start`, `start + step`, `start + 2*step`, … up to (and including) `stop`. Default `step` is `1`. Starter: `exercises/4_stepper.rb`.

5. **Plugin: timestamper**: a third plugin (`plugins/timestamper.rb`) that adds a `timestamp` method returning the current time as ISO 8601. Test it by adding it to the `plugins.rb` demo. Starter: `exercises/5_timestamper.rb`.

6. **Shelter `oldest_by_species`**: extend `Shelter` with a method that returns a hash mapping species name → oldest animal of that species. Starter: `exercises/6_oldest.rb`.
