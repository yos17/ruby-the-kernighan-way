# mini_dsl.rb — declarative routing DSL
# Usage: ruby mini_dsl.rb (demo)

# Router — a tiny declarative DSL. You subclass Router and write
# a routing table that looks like English:
#
#   class App < Router
#     draw do
#       get  "/"      do "home" end
#       post "/login" do "..." end
#     end
#   end
#
# This pattern — define a class, hand it a block full of clean
# "keywords" — is the same one Rails uses for routes, migrations,
# and models. That "internal DSL" feel is Ruby's superpower.
class Router
  # `Data.define` makes an immutable value object for one route.
  Route = Data.define(:method, :path, :handler)

  # Class-level storage: the routes table belongs to the class
  # itself, not to any single Router instance. Lazy-initialized
  # with `||=` so we don't need an explicit initialize.
  def self.routes = (@routes ||= [])

  # `inherited` is a Ruby hook fired the moment a subclass is
  # defined (here, `class App < Router`). We give each subclass its
  # own fresh @routes array; without this, every subclass would
  # share the parent's list and routes would bleed across apps.
  def self.inherited(subclass)
    subclass.instance_variable_set(:@routes, [])
  end

  # `class_eval(&block)` runs the block with `self` set to this
  # class — so `get "/path" do ... end` inside the block calls our
  # class-level `get`, not some undefined top-level method.
  def self.draw(&block) = class_eval(&block)

  # Generate five singleton methods (get/post/put/patch/delete) on
  # the class, each one capturing its verb in a closure. This one
  # loop replaces five near-identical copy-pasted definitions.
  %i[get post put patch delete].each do |verb|
    define_singleton_method(verb) do |path, &handler|
      routes << Route.new(method: verb, path: path, handler: handler)
    end
  end

  # Find the first matching route and run its handler.
  def self.dispatch(method, path)
    route = routes.find { |r| r.method == method && r.path == path }
    return "404 not found" unless route
    route.handler.call
  end
end

if __FILE__ == $PROGRAM_NAME
  class App < Router
    draw do
      get  "/"        do "home" end
      get  "/about"   do "about page" end
      post "/signup"  do "signed up!" end
    end
  end

  puts App.dispatch(:get,  "/")
  puts App.dispatch(:get,  "/about")
  puts App.dispatch(:post, "/signup")
  puts App.dispatch(:get,  "/missing")
end
