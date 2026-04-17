# mini_dsl.rb — declarative routing DSL
# Usage: ruby mini_dsl.rb (demo)

class Router
  Route = Data.define(:method, :path, :handler)

  # Keep the route table on the class, since the DSL writes class-level data.
  def self.routes = (@routes ||= [])

  # Give each subclass its own route table instead of sharing the parent's.
  def self.inherited(subclass)
    subclass.instance_variable_set(:@routes, [])
  end

  # Evaluate the routing block in the class's context.
  def self.draw(&block) = class_eval(&block)

  # Define one DSL method per HTTP verb, such as get or post.
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
