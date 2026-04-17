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
