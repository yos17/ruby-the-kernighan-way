# Exercise 5 — Rack middleware
#
# Middleware is a Rack app that wraps another Rack app. It can log, time,
# transform, or short-circuit requests.
#
# Pattern:
#   class LogMiddleware
#     def initialize(app)
#       @app = app
#     end
#
#     def call(env)
#       started = Time.now
#       status, headers, body = @app.call(env)
#       duration_ms = ((Time.now - started) * 1000).round(1)
#       puts "[#{status}] #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]} (#{duration_ms}ms)"
#       [status, headers, body]
#     end
#   end
#
# Then wrap your router:
#   app = LogMiddleware.new(router)
#   # WEBrick adapter calls app.call(env) instead of router.call(env)

# TODO: implement LogMiddleware
# TODO: in your tiny_framework, wrap router with the middleware
