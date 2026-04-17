# tiny_framework.rb — compose tiny_rack + tiny_router + tiny_orm + tiny_renderer
# Usage: ruby tiny_framework.rb (then visit http://localhost:9292)

require "webrick"
require "stringio"
require_relative "tiny_router"
require_relative "tiny_orm"
require_relative "tiny_renderer"

VIEWS_DIR = File.join(__dir__, "tiny_framework_views")
Dir.mkdir(VIEWS_DIR) unless Dir.exist?(VIEWS_DIR)

File.write(File.join(VIEWS_DIR, "users_index.erb"), <<~ERB)
  <h1>Users</h1>
  <ul>
  <% users.each do |u| %>
    <li><a href="/users/<%= u[:id] %>"><%= u[:name] %></a></li>
  <% end %>
  </ul>
ERB

File.write(File.join(VIEWS_DIR, "users_show.erb"), <<~ERB)
  <h1><%= user[:name] %></h1>
  <p>role: <%= user[:role] %></p>
  <p><a href="/users">back</a></p>
ERB

class User < Model
end

User.create(name: "Yosia", role: "admin")
User.create(name: "Alice", role: "user")
User.create(name: "Bob",   role: "user")

renderer = Renderer.new(VIEWS_DIR)
router   = Router.new

router.get("/") do |params|
  '<h1>tiny_framework</h1><p>try <a href="/users">/users</a></p>'
end

router.get("/users") do |params|
  renderer.render("users_index", users: User.all)
end

router.get("/users/:id") do |params|
  user = User.find(params[:id].to_i)
  renderer.render("users_show", user: user.to_h)
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
puts "tiny_framework on http://localhost:9292/  (Ctrl+C to stop)"
server.start
