# shelter.rb — animal shelter with class hierarchy
# Usage: ruby shelter.rb (demo)

# Animal — the base class every specific animal inherits from.
# It defines the shared state (name, age) and the contract
# (every animal can `speak` and has a `description`).
class Animal
  # `attr_reader` generates `name` and `age` getter methods that
  # simply return @name and @age. It saves us writing boilerplate.
  attr_reader :name, :age

  # Store the common data every animal shares.
  def initialize(name, age)
    @name = name
    @age  = age
  end

  # Force each subclass to provide its own sound.
  def speak
    raise NotImplementedError, "#{self.class} must implement speak"
  end

  # Build a readable one-line summary of the animal.
  def description = "#{self.class.name}(#{@name}, age #{@age})"
end

class Dog < Animal
  # Dogs override the base sound with a bark.
  def speak = "#{@name}: woof!"
end

class Cat < Animal
  # Cats override the base sound with a meow.
  def speak = "#{@name}: meow."
end

class Bird < Animal
  # Birds add one more piece of state on top of Animal's name and age.
  # `super(name, age)` calls the parent's `initialize` with these
  # exact arguments. (A bare `super` would forward *all* of our
  # arguments, including `can_fly:`, which Animal doesn't accept.)
  def initialize(name, age, can_fly: true)
    super(name, age)
    @can_fly = can_fly
  end

  # Birds override the base sound with a tweet.
  def speak = "#{@name}: tweet!"

  # Reuse Animal's description, then add the bird-specific detail.
  # Bare `super` (no parens) means "call the parent's method with
  # the same arguments I received" — handy here since description
  # takes none.
  def description
    super + (@can_fly ? " (can fly)" : " (can't fly)")
  end
end

# Shelter — a collection of Animals. Including Enumerable means
# any `each` implementation turns this class into a first-class
# collection (`select`, `map`, `group_by` all work automatically).
class Shelter
  include Enumerable

  # Start with an empty collection of admitted animals.
  def initialize
    @animals = []
  end

  # Add one animal and return self so calls can be chained.
  def admit(animal)
    @animals << animal
    self
  end

  # Let Enumerable methods iterate through the animals.
  def each(&block) = @animals.each(&block)

  # Group the animals by their class name for a simple species summary.
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
