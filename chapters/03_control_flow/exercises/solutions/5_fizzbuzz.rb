# Solution to Exercise 5
1.upto(30) do |n|
  puts case [n % 3, n % 5]
       in [0, 0] then "FizzBuzz"
       in [0, _] then "Fizz"
       in [_, 0] then "Buzz"
       else            n
       end
end
