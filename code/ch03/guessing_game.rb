#!/usr/bin/env ruby
# guessing_game.rb — number guessing game

SECRET = rand(1..100)
MAX    = 7
attempts = 0

puts "I'm thinking of a number between 1 and 100."
puts "You have #{MAX} guesses."

loop do
  attempts += 1
  remaining = MAX - attempts

  print "\nGuess ##{attempts}: "
  guess = gets.chomp.to_i

  if guess < 1 || guess > 100
    puts "Please guess between 1 and 100."
    attempts -= 1
    next
  end

  case guess <=> SECRET
  when -1 then puts "Too low!  #{remaining > 0 ? "#{remaining} left." : "Last guess!"}"
  when  1 then puts "Too high! #{remaining > 0 ? "#{remaining} left." : "Last guess!"}"
  when  0
    puts "🎉 Correct! You got it in #{attempts} #{attempts == 1 ? "guess" : "guesses"}."
    break
  end

  if attempts >= MAX
    puts "\n💀 Game over! The number was #{SECRET}."
    break
  end
end
