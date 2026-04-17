# Exercise 6 — Shelter#oldest_by_species
#
# Return a hash {species_name => oldest_animal_of_that_species}.
#
# Reuse the classes from examples/shelter.rb. (For this exercise, load it.)

require_relative "../examples/shelter"

class Shelter
  # TODO: def oldest_by_species
end

if __FILE__ == $PROGRAM_NAME
  shelter = Shelter.new
  shelter.admit(Dog.new("Rex", 3))
         .admit(Cat.new("Whiskers", 5))
         .admit(Dog.new("Buddy", 1))
         .admit(Bird.new("Tweety", 2))

  # puts shelter.oldest_by_species
  # => {"Dog" => Dog(Rex, 3), "Cat" => Cat(Whiskers, 5), "Bird" => Bird(Tweety, 2) (can fly)}
end
