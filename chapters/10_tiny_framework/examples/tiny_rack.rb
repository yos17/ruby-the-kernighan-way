# tiny_rack.rb — hello-world Rack-shaped app, no gems beyond webrick
# Usage: ruby tiny_rack.rb (then visit http://localhost:9292)

require "webrick"
require "stringio"

# A Rack app is any object that responds to `call(env)` and returns
# a 3-element array: [status, headers, body]. That's the whole
# contract. We define ours as a lambda for maximum minimalism.
#
# `env` is a hash the server hands us, keyed by strings like
# "REQUEST_METHOD" and "PATH_INFO" — the exact shape mandated by
# the Rack spec (and copied from Python's WSGI).
APP = ->(env) {
  body = "hello from tiny_rack\nyou requested: #{env["PATH_INFO"]}\n"
  # Status 200 = OK. Body must be iterable (here, a one-element
  # array of strings). The server walks it piece by piece so you
  # can stream big responses without holding them all in memory.
  [200, { "Content-Type" => "text/plain" }, [body]]
}

# WEBrick is a tiny HTTP server that ships with Ruby — zero gems
# to install. Real deployments use Puma or Falcon, but WEBrick is
# perfect for learning because nothing is hidden.
server = WEBrick::HTTPServer.new(Port: 9292, Logger: WEBrick::Log.new(File::NULL))

# `mount_proc("/")` says "for any URL starting with /, run this
# block". The block gets the raw WEBrick request and response —
# we translate between WEBrick's world and Rack's env hash.
server.mount_proc("/") do |req, res|
  env = {
    "REQUEST_METHOD" => req.request_method,
    "PATH_INFO"      => req.path,
    "QUERY_STRING"   => req.query_string.to_s,
    # Rack expects `rack.input` to be an IO-like object. StringIO
    # wraps the body string so the app can read it with .read/.gets.
    "rack.input"     => StringIO.new(req.body || "")
  }
  # Destructure the Rack triple into three local variables.
  status, headers, body_parts = APP.call(env)
  res.status = status
  headers.each { |k, v| res[k] = v }
  # `+""` creates a *mutable* empty string (Ruby strings are
  # frozen by default with `# frozen_string_literal: true`). We
  # append each body part into one string to hand to WEBrick.
  body = +""
  body_parts.each { |p| body << p }
  res.body = body
end

# `trap("INT")` installs a handler for Ctrl+C (SIGINT) — when the
# user hits Ctrl+C we shut the server down cleanly instead of
# dying mid-request with a stack trace.

trap("INT") { server.shutdown }
puts "tiny_rack on http://localhost:9292/  (Ctrl+C to stop)"
server.start
