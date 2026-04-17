# Exercise 5 — small error hierarchy
#
# AppError < StandardError
# NotFound < AppError
# Unauthorized < AppError
# BadRequest < AppError
#
# Each takes a message via super(message) in initialize.
# Demonstrate that:
#   - rescue AppError catches all three
#   - rescue NotFound catches only NotFound

# TODO: define the hierarchy

# TODO: write a `simulate(kind)` function that raises one of the four,
#       then a demo block that catches generally vs specifically.
