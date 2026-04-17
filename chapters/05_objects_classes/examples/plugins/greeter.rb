# Greeter — plugin module. When mixed into a Host, adds a `greet`
# method. `def greet(name) = ...` is Ruby 3's endless-method syntax:
# a one-expression method with no `end` keyword.
module Greeter
  def greet(name) = "Hello, #{name}!"
end
