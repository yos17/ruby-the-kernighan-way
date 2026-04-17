# Exercise 1 — Add POST with body parsing
#
# Extend tiny_router.rb so POST handlers receive a parsed body.
# Body comes as URL-encoded form data (Content-Type: application/x-www-form-urlencoded):
#   name=Yosia&role=admin
#
# Hint:
#   require "uri"
#   body_string = env["rack.input"].read
#   form = URI.decode_www_form(body_string).to_h
#
# Add a route:
#   router.post("/users") do |params, body|
#     User.create(name: body["name"], role: body["role"])
#     "<p>created</p>"
#   end
#
# Test with curl:
#   curl -X POST -d 'name=Carol&role=user' http://localhost:9292/users

# TODO: extend Router#call to parse body for POST/PUT/PATCH and pass it as the
# second argument to handler.call.
