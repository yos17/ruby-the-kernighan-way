# tiny_rack.rb — hello-world Rack-shaped app, no gems beyond webrick
# Usage: ruby tiny_rack.rb (then visit http://localhost:9292)

require "webrick"
require "stringio"

APP = ->(env) {
  body = "hello from tiny_rack\nyou requested: #{env["PATH_INFO"]}\n"
  [200, { "Content-Type" => "text/plain" }, [body]]
}

server = WEBrick::HTTPServer.new(Port: 9292, Logger: WEBrick::Log.new(File::NULL))
server.mount_proc("/") do |req, res|
  env = {
    "REQUEST_METHOD" => req.request_method,
    "PATH_INFO"      => req.path,
    "QUERY_STRING"   => req.query_string.to_s,
    "rack.input"     => StringIO.new(req.body || "")
  }
  status, headers, body_parts = APP.call(env)
  res.status = status
  headers.each { |k, v| res[k] = v }
  body = +""
  body_parts.each { |p| body << p }
  res.body = body
end

trap("INT") { server.shutdown }
puts "tiny_rack on http://localhost:9292/  (Ctrl+C to stop)"
server.start
