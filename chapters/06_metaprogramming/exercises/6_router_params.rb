# Exercise 6 — Router with :param-style placeholders
#
# get "/users/:id" do |params|
#   "user #{params[:id]}"
# end
#
# Router.dispatch(:get, "/users/42")  # => "user 42"
#
# Approach: when registering, convert "/users/:id" to a regex like
# %r{^/users/(?<id>[^/]+)$}.
# When dispatching, try each route's regex against the incoming path; if it
# matches, call the handler with the named captures as a symbol-keyed hash.

class Router
  Route = Data.define(:method, :pattern, :param_names, :handler)

  def self.routes = (@routes ||= [])

  def self.inherited(subclass)
    subclass.instance_variable_set(:@routes, [])
  end

  def self.draw(&block) = class_eval(&block)

  %i[get post put patch delete].each do |verb|
    define_singleton_method(verb) do |path, &handler|
      # TODO: convert path to a regex with named captures
      # TODO: extract the param names
      # TODO: routes << Route.new(method: verb, pattern: ..., param_names: ..., handler: handler)
    end
  end

  def self.dispatch(method, path)
    # TODO: find the first route where method matches AND pattern matches path
    # TODO: build a params hash from the named captures, call handler.call(params)
    # TODO: return "404 not found" if nothing matches
  end
end
