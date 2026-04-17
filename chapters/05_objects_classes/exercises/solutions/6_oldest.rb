# Solution to Exercise 6
require_relative "../../examples/shelter"

class Shelter
  def oldest_by_species
    by_species.transform_values { |animals| animals.max_by(&:age) }
  end
end

if __FILE__ == $PROGRAM_NAME
  shelter = Shelter.new
  shelter.admit(Dog.new("Rex", 3))
         .admit(Cat.new("Whiskers", 5))
         .admit(Dog.new("Buddy", 1))
         .admit(Bird.new("Tweety", 2))

  shelter.oldest_by_species.each { |species, a| puts "#{species}: #{a.description}" }
end
