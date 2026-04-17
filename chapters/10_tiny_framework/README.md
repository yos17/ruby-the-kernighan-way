# Chapter 10 — A Tiny Web Framework

This is the centerpiece chapter. Before you let Rails generate anything for you, build the moving parts once by hand. Not because you would ship this framework, but because the polished one makes more sense after you have seen the rough one.

By the end of the chapter you will have:

- `tiny_rack.rb` — a hello-world app speaking the Rack protocol
- `tiny_router.rb` — a Sinatra-style routing DSL on top of Rack
- `tiny_orm.rb` — a baby Active Record using `method_missing` for queries
- `tiny_renderer.rb` — an ERB-based template renderer
- `tiny_framework.rb` — composes all four into a working mini-Rails

Keep one terminal for the server and another for `curl`. This chapter is easiest to read when every new file can answer a real request a minute after you write it.

When you open `rails new` next chapter, the directories and files should stop looking magical. They should look familiar.

## What's a web request, mechanically?

A browser sends bytes that look like:

```
GET /posts/42 HTTP/1.1
Host: example.com
Accept: text/html
```

Your server reads those bytes, parses them into a method (`GET`), a path (`/posts/42`), headers, and (for `POST`/`PUT`) a body. Your code computes a response. Your server writes back:

```
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 124

<html><body>Post 42 says hi.</body></html>
```

That's it. Everything else is layers on top.

## Rack — the Ruby web protocol

Every Ruby web framework — Rails, Sinatra, Hanami — speaks Rack. The contract is exactly one method:

> `call(env) → [status, headers, body]`

`env` is a Hash containing the parsed request. Status is an integer (200, 404, 500). Headers are a Hash. Body is anything that responds to `each` and yields strings (an array works).

That's the whole protocol. A Rack app is anything that responds to `call(env)`. A Proc works. A class with a `call` method works.

## tiny_rack.rb

We use `WEBrick` from the stdlib (no gem install needed) as the HTTP server, and write a small adapter that translates between WEBrick's API and the Rack contract:

```ruby
# tiny_rack.rb — hello-world Rack-shaped app, no gems beyond webrick
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
```

Run:

```
$ ruby tiny_rack.rb
tiny_rack on http://localhost:9292/  (Ctrl+C to stop)
```

In another terminal:

```
$ curl http://localhost:9292/posts/42
hello from tiny_rack
you requested: /posts/42
```

The `APP` is a single lambda. The Rack interface is just *"a callable that takes env and returns the triple."* Once you grasp this, every Ruby web framework is comprehensible.

(File: `examples/tiny_rack.rb`. WEBrick is bundled with Ruby; if a recent Ruby reports it missing, `gem install webrick`.)

## tiny_router.rb

A single lambda is fine for hello-world. For real apps you want to dispatch on method + path. Sinatra's API is the gold standard:

```ruby
get  "/posts"      do ... end
get  "/posts/:id"  do |params| ... end
post "/posts"      do ... end
```

Build it:

```ruby
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
```

Wire it into the same WEBrick adapter and you have a real (tiny) framework:

```ruby
router = Router.new
router.get("/")            { '<h1>tiny_router</h1>' }
router.get("/hello/:name") { |params| "<h1>hello, #{params[:name]}!</h1>" }
# ... WEBrick adapter calls router.call(env) ...
```

Test:

```
$ curl http://localhost:9292/hello/yosia
<h1>hello, yosia!</h1>
$ curl http://localhost:9292/missing
404 not found
```

What's new.

`define_method(verb) do |path, &handler|` — generates `Router#get`, `#post`, etc. from a single loop. Same `define_method` you used in Ch 6.

The path `/hello/:name` is converted to a regex with a *named capture* `(?<name>[^/]+)`. The named captures appear on the `MatchData` object as `m[:name]`.

The `Router` itself is a Rack app — it has `call(env)` that returns the triple. Composability: the router *is* what the WEBrick adapter calls.

(File: `examples/tiny_router.rb`.)

## tiny_orm.rb

Routes need data. Active Record's API is famously expressive — `User.where(role: "admin").order(:name).limit(10)`. Let's build a baby version backed by an in-memory hash.

```ruby
class Model
  class << self
    attr_accessor :records, :next_id

    def inherited(subclass)
      subclass.records = []
      subclass.next_id = 1
    end

    def create(attrs)
      record = new(attrs.merge(id: next_id))
      records << record
      self.next_id += 1
      record
    end

    def all = records.dup

    def find(id)
      records.find { |r| r[:id] == id } or raise "no #{name} with id #{id}"
    end

    def where(attrs)
      records.select { |r| attrs.all? { |k, v| r[k] == v } }
    end

    def method_missing(name, *args)
      if name.to_s.start_with?("find_by_")
        attr = name.to_s.delete_prefix("find_by_").to_sym
        records.find { |r| r[attr] == args.first }
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.to_s.start_with?("find_by_") || super
    end
  end

  def initialize(attrs)
    @attrs = attrs
  end

  def [](key) = @attrs[key]
  def to_h    = @attrs.dup
  def inspect = "#<#{self.class.name} #{@attrs.inspect}>"
end

class User < Model; end

User.create(name: "Yosia", role: "admin")
User.create(name: "Alice", role: "user")
User.create(name: "Bob",   role: "user")

p User.all.length              # 3
p User.where(role: "user")     # the two non-admin users
p User.find_by_name("Alice")   # generated method via method_missing
p User.find(1)                 # by id
```

What's new.

`class << self ... end` opens the singleton class. Methods defined here are class methods on `Model` (and inherited by subclasses). Same as `def self.method`, but we can use `attr_accessor` for class-level state (`records`, `next_id`).

`inherited(subclass)` (Ch 6's hook) gives every subclass its own `records` and `next_id`. Without this, every model would share one global table.

`method_missing` intercepts `find_by_<column>`. For each subclass, you can call `User.find_by_name(...)`, `User.find_by_role(...)`, *for any column*, without writing those methods. This is exactly how ActiveRecord does it (with one important addition: AR uses `define_method` to *cache* the generated method on first call, so subsequent calls skip method_missing entirely).

(File: `examples/tiny_orm.rb`.)

## tiny_renderer.rb

Templates: HTML with Ruby snippets. ERB ships with Ruby and is the same engine `.html.erb` files use in Rails.

```ruby
require "erb"

class Renderer
  def initialize(template_dir = ".")
    @template_dir = template_dir
    @cache = {}
  end

  def render(name, locals = {})
    template = @cache[name] ||= ERB.new(File.read(File.join(@template_dir, "#{name}.erb")))
    bind = binding
    locals.each { |k, v| bind.local_variable_set(k, v) }
    template.result(bind)
  end
end
```

Usage:

```ruby
r = Renderer.new(views_dir)
puts r.render("greet", name: "Yosia", items: ["one", "two", "three"])
```

A template:

```erb
<h1>Hello, <%= name %>!</h1>
<ul>
<% items.each do |item| %>
  <li><%= item %></li>
<% end %>
</ul>
```

What's new.

`ERB.new(template_string)` parses an ERB template. `<%= expr %>` interpolates a value; `<% code %>` runs Ruby without inserting output.

`binding` returns the current scope's variable bindings. `template.result(binding)` evaluates the template *with that binding* — so any local variable in scope is available inside `<%= %>`.

`bind.local_variable_set(k, v)` injects each `locals` entry as a local variable. We use `binding` (instead of `instance_eval`) so the template sees `name`, `items`, etc. as local variables — the same way `.erb` files in Rails see locals passed to `render(partial: ..., locals: ...)`.

`@cache[name] ||= ...` caches the parsed template — re-reading and re-parsing on every request would be wasteful.

(File: `examples/tiny_renderer.rb`.)

## tiny_framework.rb — composing them

Now combine: a framework where you define routes that fetch data from models and render templates.

```ruby
require_relative "tiny_router"
require_relative "tiny_orm"
require_relative "tiny_renderer"

VIEWS_DIR = File.join(__dir__, "tiny_framework_views")

# Models
class User < Model; end

User.create(name: "Yosia", role: "admin")
User.create(name: "Alice", role: "user")
User.create(name: "Bob",   role: "user")

# Routing
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

# WEBrick adapter (same as tiny_rack.rb) calls router.call(env)
```

You just built a mini-Rails. The pieces:

- **HTTP-to-Rack adapter** — translates between the HTTP server and the Rack contract
- **Router** — dispatches based on method + path
- **Models** (`User < Model`) — give you a query DSL via `method_missing`
- **Templates** (ERB via `Renderer`) — turn data into HTML
- **App composition** — wires it all together

The next two chapters are about Real Rails. When you see `app/models/user.rb`, `app/controllers/users_controller.rb`, `app/views/users/index.html.erb`, you'll recognize the corresponding piece you wrote here.

(Files: `examples/tiny_rack.rb`, `examples/tiny_router.rb`, `examples/tiny_orm.rb`, `examples/tiny_renderer.rb`, `examples/tiny_framework.rb`.)

## Common pitfalls

- **Leaking IOs and sockets.** A handler that opens `File.open(path)` without a block (or without `ensure ... close`) leaks a file descriptor on every request. Eventually the process runs out and the server stops accepting connections. Same for raw TCP sockets. Use the block form: `File.open(path) { |f| ... }` — Ruby closes for you.
- **Shared state is not thread-safe.** `Model.records` is a single mutable array. Under WEBrick's single-threaded loop you don't notice; under Puma with multiple threads, two requests calling `Model.create` can race — same `next_id`, lost writes, half-built objects. Real Active Record sidesteps this with the database (rows, transactions, sequences). For this tiny ORM, treat it as a single-threaded toy or wrap mutations in a `Mutex`.
- **Greedy regex routes.** Writing the path pattern as `(?<id>.+)` instead of `[^/]+` makes `/posts/1/edit` match `id = "1/edit"`. Always anchor each `:param` to "no slashes": `[^/]+`. Test routes with adjacent paths (`/posts/1` and `/posts/1/edit`) before trusting them.
- **Unsafe ERB interpolation.** `<%= user_input %>` in our `tiny_renderer` interpolates raw — a user named `<script>alert(1)</script>` becomes executable HTML. Real Rails uses `ActionView::Base` with output safety: `<%= %>` HTML-escapes by default, `<%== %>` (or a `.html_safe` string) opts out. For your tiny renderer, escape with `CGI.escapeHTML(value)` before interpolating any value that came from a request.

## Where Rails goes further

Your tiny framework is the bones. Rails adds, in roughly the order you'll meet them:

- **Asset pipeline (Propshaft + import maps).** Hashing, fingerprinting, and serving CSS/JS without a Node build step.
- **Active Job + Solid Queue.** A unified job interface so `MyJob.perform_later(args)` runs work outside the request cycle, backed by the database.
- **Action Cable.** WebSockets for live updates, used by Hotwire's Turbo Streams.
- **Sessions, cookies, CSRF.** Signed/encrypted cookies, automatic CSRF token injection in forms, session storage.
- **Request lifecycle helpers.** `params`, `flash`, `cookies`, `session`, `request`, `response` — all standardized objects on `ActionController::Base`.
- **Generators.** `bin/rails generate` for models, controllers, migrations, jobs, mailers — repeatable boilerplate.
- **Autoloading via Zeitwerk.** No `require` at the top of every file. The constant `User` triggers a load of `app/models/user.rb` by naming convention.
- **Encrypted credentials store.** `config/credentials.yml.enc` plus a master key — secrets versioned into the repo, decrypted at boot.

You won't write any of these by hand. You'll use them all.

## What you learned

| Concept | Key point |
|---|---|
| Rack | a callable that takes `env`, returns `[status, headers, body]` |
| HTTP-to-Rack adapter | translates an HTTP server's API into Rack's |
| `WEBrick::HTTPServer` | the stdlib HTTP server, useful for tiny demos |
| Path patterns with `:param` | converted to regex with named captures |
| `MatchData[:name]` | named captures from a regex match |
| `Router#call(env)` | composing — the router *is* a Rack app |
| `class << self` | open the singleton class for class methods |
| `Model.records` via `attr_accessor` on the class | per-subclass class-level state |
| `inherited` hook | give every subclass its own table |
| `method_missing` for `find_by_*` | how Active Record makes column-named methods |
| `ERB.new(s).result(binding)` | run a template against the current binding |
| `binding.local_variable_set(k, v)` | inject locals into the binding |
| Composition | router → renders → uses models — three pieces, one app |

## Going deeper

- Read Sinatra's source — `https://github.com/sinatra/sinatra/blob/main/lib/sinatra/base.rb`. Around 2,000 lines of Ruby implement everything Sinatra is. Find the `route!` method and trace one request through it.
- Read Roda — `https://github.com/jeremyevans/roda/blob/master/lib/roda.rb`. A different routing philosophy: tree dispatch instead of a flat route table. Read it as a counterpoint to Sinatra.
- Read `ActionDispatch::Routing` in Rails — `https://github.com/rails/rails/tree/main/actionpack/lib/action_dispatch/routing`. Start with `mapper.rb` (the `resources :posts` DSL) and `route_set.rb` (the dispatcher). It is much bigger than your `Router`, but the core idea — match method+path, capture params, invoke a callable — is what you wrote.

## Exercises

1. **Add POST**: extend `tiny_router.rb` to handle POST requests with a body. Read `env["rack.input"]`, parse `name=foo&role=bar` (use `URI.decode_www_form(body)`). Add a route `post "/users" do |params, body| ... end` that creates a User. Starter: `exercises/1_router_post.rb`.

2. **`update` and `destroy`**: extend `tiny_orm.rb` with `User.update(id, attrs)` and `User.destroy(id)`. Starter: `exercises/2_orm_update_destroy.rb`.

3. **Layouts**: extend `tiny_renderer.rb` with a `layout` parameter that wraps the rendered template inside a parent template. Hint: use a layout template like `<html><body><%= yield %></body></html>` and make `render` substitute the inner result. Starter: `exercises/3_renderer_layout.rb`.

4. **Persist tiny_orm**: extend `Model` so it dumps `records` to a JSON file on every `create`. On startup, if the file exists, load from it. (Make it pluggable per subclass — `class User < Model; persist_to "users.json"; end`.) Starter: `exercises/4_orm_persist.rb`.

5. **Middleware**: write a simple Rack middleware — a class that wraps a Rack app, logs each request's method/path/status to stdout, then returns the inner app's response. Wrap your `tiny_framework`'s router with it. Starter: `exercises/5_middleware.rb`.

6. **Counter app**: build a complete app on top of your tiny framework — a click counter that persists between requests. Routes: `GET /` shows the counter, `POST /increment` adds 1, `POST /reset` zeros it. Use forms (`<form method="POST" action="/increment">`). Starter: `exercises/6_counter_app.rb`.
