# tiny_router.rb — a Sinatra-style routing DSL on Rack
# Usage: ruby tiny_router.rb (then visit http://localhost:9292)

require "webrick"
require "stringio"

class Router
  Route = Data.define(:method, :pattern, :param_names, :handler)

  def initialize
    @routes = []
  end

  %i[get post put patch delete].each do |verb|
    define_method(verb) do |path, &handler|
      param_names = path.scan(/:(\w+)/).flatten.map(&:to_sym)
      pattern_str = path.gsub(/:(\w+)/, '(?<\1>[^/]+)')
      pattern     = Regexp.new("^#{pattern_str}$")
      @routes << Route.new(method: verb.to_s.upcase, pattern: pattern, param_names: param_names, handler: handler)
    end
  end

  def call(env)
    method = env["REQUEST_METHOD"]
    path   = env["PATH_INFO"]
    @routes.each do |route|
      next unless route.method == method
      m = route.pattern.match(path) or next
      params = route.param_names.to_h { |name| [name, m[name]] }
      body   = route.handler.call(params).to_s
      return [200, { "Content-Type" => "text/html" }, [body]]
    end
    [404, { "Content-Type" => "text/plain" }, ["404 not found\n"]]
  end
end

if __FILE__ == $PROGRAM_NAME
  router = Router.new
  router.get("/") do |params|
    '<h1>tiny_router</h1><p>try <a href="/hello/yosia">/hello/yosia</a></p>'
  end
  router.get("/hello/:name") do |params|
    "<h1>hello, #{params[:name]}!</h1>"
  end

  server = WEBrick::HTTPServer.new(Port: 9292, Logger: WEBrick::Log.new(File::NULL))
  server.mount_proc("/") do |req, res|
    env = {
      "REQUEST_METHOD" => req.request_method,
      "PATH_INFO"      => req.path,
      "QUERY_STRING"   => req.query_string.to_s,
      "rack.input"     => StringIO.new(req.body || "")
    }
    status, headers, body_parts = router.call(env)
    res.status = status
    headers.each { |k, v| res[k] = v }
    res.body = body_parts.join
  end

  trap("INT") { server.shutdown }
  puts "tiny_router on http://localhost:9292/  (Ctrl+C to stop)"
  server.start
end
