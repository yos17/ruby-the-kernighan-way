# Solution to Exercise 6
class Router
  Route = Data.define(:method, :pattern, :param_names, :handler)

  def self.routes = (@routes ||= [])

  def self.inherited(subclass)
    subclass.instance_variable_set(:@routes, [])
  end

  def self.draw(&block) = class_eval(&block)

  %i[get post put patch delete].each do |verb|
    define_singleton_method(verb) do |path, &handler|
      param_names = path.scan(/:(\w+)/).flatten.map(&:to_sym)
      pattern_str = path.gsub(/:(\w+)/, '(?<\1>[^/]+)')
      pattern     = Regexp.new("^#{pattern_str}$")
      routes << Route.new(method: verb, pattern: pattern, param_names: param_names, handler: handler)
    end
  end

  def self.dispatch(method, path)
    routes.each do |r|
      next unless r.method == method
      m = r.pattern.match(path) or next
      params = r.param_names.to_h { |name| [name, m[name]] }
      return r.handler.call(params)
    end
    "404 not found"
  end
end

if __FILE__ == $PROGRAM_NAME
  class App < Router
    draw do
      get "/users/:id"      do |params| "user #{params[:id]}" end
      get "/posts/:id/edit" do |params| "edit post #{params[:id]}" end
    end
  end

  puts App.dispatch(:get, "/users/42")
  puts App.dispatch(:get, "/posts/7/edit")
  puts App.dispatch(:get, "/missing")
end
