# Exercise 4 — Registerable
#
# module Registerable
#   def self.classes; @classes ||= []; end
#   def self.included(klass); classes << klass; end
# end
#
# class A; include Registerable; end
# class B; include Registerable; end
#
# Registerable.classes  # => [A, B]

# TODO: define Registerable module with the included hook
