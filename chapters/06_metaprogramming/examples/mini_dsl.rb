# mini_dsl.rb — declarative routing DSL
# Usage: ruby mini_dsl.rb (demo)

class Router
  Route = Data.define(:method, :path, :handler)

  def self.routes = (@routes ||= [])

  def self.inherited(subclass)
    subclass.instance_variable_set(:@routes, [])
  end

  def self.draw(&block) = class_eval(&block)

  %i[get post put patch delete].each do |verb|
    define_singleton_method(verb) do |path, &handler|
      routes << Route.new(method: verb, path: path, handler: handler)
    end
  end

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
