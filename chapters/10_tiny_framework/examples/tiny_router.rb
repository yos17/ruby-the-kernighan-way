# tiny_router.rb — a Sinatra-style routing DSL on Rack
# Usage: ruby tiny_router.rb (then visit http://localhost:9292)

require "webrick"
require "stringio"

# Router — a Sinatra-style routing layer on top of Rack. It maps
# a method+path combo like GET "/users/:id" onto a block, and
# returns a Rack triple ready for the server to send back.
class Router
  # Each route is a value record: the HTTP method, the compiled
  # regex used to match the path, the names of the :params in that
  # path, and the block to run when matched.
  Route = Data.define(:method, :pattern, :param_names, :handler)

  # Start with no routes registered.
  def initialize
    @routes = []
  end

  # Define one instance method per HTTP verb so routes read like
  # router.get("/path"). Each call captures the verb in a closure.
  #
  # The path "/users/:id" is turned into the regex /^\/users\/(?<id>[^\/]+)$/,
  # using a *named capture group*. `(?<id>[^/]+)` means "one or
  # more non-slash characters, remember them under the name `id`".
  # Later, `m[:id]` pulls that value out of the MatchData.
  %i[get post put patch delete].each do |verb|
    define_method(verb) do |path, &handler|
      # Pull ":id", ":slug" etc. out of the raw path string.
      param_names = path.scan(/:(\w+)/).flatten.map(&:to_sym)
      # Rewrite ":id" into the named-capture form for the regex.
      pattern_str = path.gsub(/:(\w+)/, '(?<\1>[^/]+)')
      pattern     = Regexp.new("^#{pattern_str}$")
      @routes << Route.new(method: verb.to_s.upcase, pattern: pattern, param_names: param_names, handler: handler)
    end
  end

  # Match the incoming request and return a Rack response triple.
  # Walk routes in order; the first match wins.
  def call(env)
    method = env["REQUEST_METHOD"]
    path   = env["PATH_INFO"]
    @routes.each do |route|
      next unless route.method == method
      # `m or next` — shorthand for "if no match, skip this route".
      # The result of `Regexp#match` is a MatchData or nil.
      m = route.pattern.match(path) or next
      # Build a {name => value} hash by pulling each named capture
      # out of the MatchData. `to_h { |x| [k, v] }` is the idiomatic
      # way to build a hash from an enumerable.
      params = route.param_names.to_h { |name| [name, m[name]] }
      body   = route.handler.call(params).to_s
      return [200, { "Content-Type" => "text/html" }, [body]]
    end
    # No route matched — return the Rack 404 triple.
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
