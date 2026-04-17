# Chapter 7 — Files, Errors, the Outside World

The previous chapters stayed mostly inside Ruby. This chapter is about the places where programs touch the world and the world pushes back. Files are missing. JSON is malformed. Servers time out. Environment variables are unset. That is ordinary programming, not an edge case.

Three programs. `logwatch.rb` tails a changing file and alerts on matches. `config_loader.rb` merges defaults with outside input. `tiny_http_client.rb` talks to a remote server without pretending the network is polite. Each one forces you to meet Ruby's file, error, and environment machinery the moment it's needed.

## First build: logwatch.rb

Run this in one terminal. In another, append lines to the log file. Whenever a line matches your pattern, `logwatch` prints an alert.

```ruby
# logwatch.rb — tail a file, alert when a pattern shows up
# Usage: ruby logwatch.rb <pattern> <file>

require "set"

pattern = Regexp.new(ARGV[0]) if ARGV[0]
filename = ARGV[1]
abort "usage: logwatch.rb PATTERN FILE" unless pattern && filename

seen = Set.new
loop do
  break unless File.exist?(filename)
  File.foreach(filename).with_index do |line, i|
    next if seen.include?(i)
    seen << i
    if pattern.match?(line)
      puts "[ALERT line #{i + 1}] #{line.chomp}"
    end
  end
  sleep 1
end
```

Run it:

```
# terminal 1
$ ruby logwatch.rb ERROR app.log

# terminal 2
$ echo "2026-04-17 INFO starting"   >> app.log
$ echo "2026-04-17 ERROR db timeout" >> app.log
$ echo "2026-04-17 INFO recovered"   >> app.log

# terminal 1 prints:
[ALERT line 2] 2026-04-17 ERROR db timeout
```

Four new things.

### `File.foreach` and `File.exist?`

```ruby
File.exist?("app.log")           # => true/false
File.foreach("app.log") { |l| puts l }
```

`File.foreach` reads the file one line at a time. It never loads the whole file into memory, so it handles log files of any size. Every iteration yields one line (including the trailing newline).

`File.exist?(path)` answers yes/no. Useful before you try to read.

### `Regexp.new` — compile a pattern at runtime

```ruby
pattern = Regexp.new(ARGV[0])
pattern.match?("2026-04-17 ERROR db timeout")   # => true or false
```

`Regexp.new(str)` takes a string and turns it into a regex. You use this form when the pattern comes from input you don't control (a command-line argument, a config file). When you know the pattern at write-time, the literal form `/ERROR/` is cleaner.

### `Set` — answer "have I seen this?" fast

```ruby
require "set"

seen = Set.new
seen << 1; seen << 2; seen << 1
seen                 # => #<Set: {1, 2}>
seen.include?(1)     # => true, in constant time
```

A `Set` is an array that (a) keeps no duplicates and (b) answers `include?` in constant time. `Array#include?` scans the whole array; `Set#include?` doesn't. `logwatch` uses a set to remember which line indexes it has already alerted on, so the same line never alerts twice as the loop revisits the file.

### `loop do ... end` and `sleep`

```ruby
loop do
  # ... do work ...
  sleep 1
end
```

`loop` is Ruby's infinite loop. You leave it by raising, returning, or `break`. The user stops `logwatch` with Ctrl+C.

`sleep 1` pauses the process for one second. Polling every second is simple and good enough for a small log file. Production tools use `inotify` or `kqueue` to watch for changes without polling — that's a Chapter-13-sized topic, not a Ch-7 one.

(File: `examples/logwatch.rb`. Test with `examples/app.log`.)

## Second build: config_loader.rb

Every real program reads configuration from somewhere. The standard pattern is to layer: sensible defaults, then a config file (JSON here), then environment variables for the final overrides. ENV always wins — you want the sysadmin to be able to override *anything* without editing files.

```ruby
# config_loader.rb — layered config (defaults < json < env)
# Usage: ruby config_loader.rb [config.json]

require "json"

class ConfigError < StandardError; end

class Config
  DEFAULTS = {
    host: "localhost",
    port: 8080,
    log_level: "info",
    database_url: "sqlite::memory:"
  }.freeze

  def self.load(path = nil)
    config = DEFAULTS.dup
    config.merge!(load_file(path)) if path && File.exist?(path)
    config.merge!(load_env)
    new(config)
  end

  def self.load_file(path)
    JSON.parse(File.read(path), symbolize_names: true)
  rescue JSON::ParserError => e
    raise ConfigError, "invalid JSON in #{path}: #{e.message}"
  end

  def self.load_env
    DEFAULTS.keys.each_with_object({}) do |key, h|
      env_value = ENV["APP_#{key.upcase}"]
      h[key] = env_value if env_value
    end
  end

  attr_reader :data

  def initialize(data) = @data = data.freeze
  def [](key) = @data.fetch(key)
  def to_s   = @data.map { |k, v| "  #{k}: #{v}" }.join("\n")
end

if __FILE__ == $PROGRAM_NAME
  config = Config.load(ARGV[0])
  puts "config:"
  puts config
end
```

Run it:

```
$ ruby config_loader.rb
config:
  host: localhost
  port: 8080
  log_level: info
  database_url: sqlite::memory:

$ APP_PORT=9000 APP_LOG_LEVEL=debug ruby config_loader.rb
config:
  host: localhost
  port: 9000
  log_level: debug
  database_url: sqlite::memory:
```

Five new things.

### JSON

```ruby
require "json"

JSON.parse('{"name":"Yosia"}')                        # => {"name"=>"Yosia"}
JSON.parse('{"name":"Yosia"}', symbolize_names: true) # => {name: "Yosia"}
{name: "Yosia"}.to_json                               # => '{"name":"Yosia"}'
JSON.pretty_generate({name: "Yosia"})                 # multi-line, indented
```

`JSON.parse` turns a JSON string into a Ruby hash. By default the keys are strings, because JSON only has strings. `symbolize_names: true` converts them to symbols — which is what you almost always want when the JSON represents config you control. Leave string keys when the JSON came from an external system whose shape you don't own.

### `.freeze` and `.dup`

```ruby
DEFAULTS = { host: "localhost", port: 8080 }.freeze
DEFAULTS[:port] = 9000     # raises FrozenError — hash is frozen

copy = DEFAULTS.dup        # shallow copy — copy is NOT frozen
copy[:port] = 9000         # works
```

Constants aren't automatically frozen in Ruby. `NAMES = ["Alice"]` can still be mutated — `NAMES << "Bob"` works and silently shares state across the program. Freeze the value to prevent that: `["Alice"].freeze`. Any attempt to mutate a frozen object raises `FrozenError`.

`.dup` makes a shallow copy. When you need a working version of something frozen, dup it first.

### `begin / rescue / raise`

```ruby
def self.load_file(path)
  JSON.parse(File.read(path), symbolize_names: true)
rescue JSON::ParserError => e
  raise ConfigError, "invalid JSON in #{path}: #{e.message}"
end
```

Methods get an implicit `begin` around their body, so you can write `rescue` at the method level without an explicit `begin`. Here we catch a low-level `JSON::ParserError` and re-raise a domain-specific `ConfigError` with a clearer message. Callers of `Config.load` only need to know about `ConfigError`; they shouldn't care that it's really a JSON problem.

`rescue X => e` catches class `X` and binds the exception object to `e`. You can read `e.message` or `e.backtrace` for details.

### Custom exception classes

```ruby
class ConfigError < StandardError; end
```

Subclass `StandardError`. That's it. This one line buys you a type the caller can rescue specifically: `rescue ConfigError`. Never `rescue Exception` (it catches `SignalException` and `SystemExit`), and avoid bare `rescue` (it catches every bug you wanted to crash on). Pick a class.

### `ENV`

```ruby
ENV["APP_PORT"]            # => "9000" or nil
ENV.fetch("APP_PORT")      # => "9000" or raises KeyError
ENV.fetch("APP_PORT", "8080")  # default if missing
```

`ENV` is a hash-like object wrapping the process environment. Values are always strings (so `ENV["PORT"].to_i` is common). Use `ENV.fetch` for required values — silent `nil`s from `ENV["X"]` propagate until something far away crashes. `config_loader` uses `ENV[...]` because missing is a valid "no override here" signal.

`each_with_object({})` in `load_env` accumulates into a hash: the block runs once per key, with `h` as the (stable) target.

(File: `examples/config_loader.rb`. Try it with a JSON file: `echo '{"port":7000}' > c.json && ruby config_loader.rb c.json`.)

## Third build: tiny_http_client.rb

A small HTTP client for JSON APIs. It retries transient network failures, raises a typed error for non-2xx responses, and parses the body on success.

```ruby
# tiny_http_client.rb — minimal HTTP client for JSON APIs
# Usage: ruby tiny_http_client.rb [url]

require "net/http"
require "uri"
require "json"

class HttpClient
  class HttpError < StandardError
    attr_reader :status

    def initialize(status, message)
      @status = status
      super(message)
    end
  end

  def initialize(base_url) = @base_url = base_url

  def get(path)
    uri = URI.join(@base_url, path)
    response = with_retry { Net::HTTP.get_response(uri) }
    raise HttpError.new(response.code.to_i, response.body) unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body, symbolize_names: true)
  end

  private

  def with_retry(max: 3)
    attempts = 0
    begin
      attempts += 1
      yield
    rescue Net::OpenTimeout, Errno::ECONNRESET => e
      retry if attempts < max
      raise
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  url = ARGV[0] || "https://api.github.com/users/octocat"
  uri = URI(url)
  base = "#{uri.scheme}://#{uri.host}"
  path = uri.request_uri

  client = HttpClient.new(base)
  begin
    data = client.get(path)
    puts data.inspect[0..200]
  rescue HttpClient::HttpError => e
    puts "HTTP #{e.status}: #{e.message[0..100]}"
  rescue SocketError => e
    puts "network error: #{e.message}"
  end
end
```

Run it (needs a working network):

```
$ ruby tiny_http_client.rb
{:login=>"octocat", :id=>583231, :node_id=>"MDQ6VXNlcjU4MzIzMQ==", ...
```

Four new things.

### `Net::HTTP` and `URI`

```ruby
require "net/http"
require "uri"

uri      = URI("https://api.github.com/users/octocat")
response = Net::HTTP.get_response(uri)
response.code           # => "200"        (string)
response.body           # => '{"login":"octocat",...}'
response.is_a?(Net::HTTPSuccess)   # => true
```

`URI(...)` parses a URL. `Net::HTTP.get_response(uri)` performs a GET and returns a response object. `Net::HTTPSuccess` is the parent class of all 2xx responses — checking `is_a?` is the idiomatic way to ask "did it work?"

`URI.join(base, path)` resolves a relative path against a base URL, handling slashes the way the RFC wants.

### A custom exception with state

```ruby
class HttpError < StandardError
  attr_reader :status

  def initialize(status, message)
    @status = status
    super(message)
  end
end
```

When the exception should carry extra data (a status code, a missing key, a row number), give it an `initialize`, stash the data in `@-variables`, and call `super(message)` so `e.message` still works. Callers can then `rescue HttpError => e; puts e.status`.

### `retry`

```ruby
def with_retry(max: 3)
  attempts = 0
  begin
    attempts += 1
    yield
  rescue Net::OpenTimeout, Errno::ECONNRESET => e
    retry if attempts < max
    raise
  end
end
```

Inside a rescue, `retry` jumps back to the top of the `begin` block. Combined with a counter (`attempts < max`) it becomes a bounded retry. If we exhaust the retries, plain `raise` re-throws the exception we just caught, unchanged.

Rescue can name multiple exception classes separated by commas — here we retry on two specific transient errors, and let any other exception escape.

### `yield`

`with_retry` doesn't accept the block with an explicit `&block` parameter. It just calls `yield`, which runs whatever block the caller passed. You saw this in Chapter 4; this is a useful second example. Ruby's block-passing is invisible by default — every method implicitly accepts a block, and `yield` runs it.

(File: `examples/tiny_http_client.rb`. Requires network access to test.)

## More tools you'll need

The three programs introduced the core. The rest comes up often enough to know by name.

### File — the full picture

```ruby
File.read("notes.txt")                          # whole file as one string
File.readlines("notes.txt")                     # array of lines (with \n)
File.readlines("notes.txt", chomp: true)        # array of lines (without \n)
File.foreach("notes.txt") { |line| puts line }  # streaming (memory-safe)
File.size("notes.txt")                          # bytes
File.mtime("notes.txt")                         # Time of last modification
```

Pick `foreach` for large files, `read` for small ones, `readlines` when you actually want an array.

```ruby
File.write("out.txt", "first\nsecond\n")    # whole file (truncates)
File.write("out.txt", "more\n", mode: "a")  # append

File.open("out.txt", "w") do |f|
  f.puts "line 1"
  f.puts "line 2"
end   # auto-closes when the block exits, even on exception
```

Use the block form for multi-write operations — without it, a crash mid-write leaks the file handle. Mode strings: `"r"` read, `"w"` write (truncates), `"a"` append, `"r+"` read+write, `"wb"`/`"rb"` binary on Windows.

### Paths that work everywhere

```ruby
File.join("data", "users", "yosia.json")
# => "data/users/yosia.json"  on Unix
# => "data\users\yosia.json"  on Windows

__FILE__       # path to the current source file
__dir__        # directory of the current source file
File.basename("/tmp/foo.rb")    # => "foo.rb"
File.extname("/tmp/foo.rb")     # => ".rb"
```

`File.join(__dir__, "data.json")` is the standard way to load a file next to the script regardless of where the user runs it from.

### Directories and globs

```ruby
Dir.exist?("logs")
Dir.mkdir("logs")              # one level
FileUtils.mkdir_p("a/b/c")     # nested (require "fileutils")
Dir.children("logs")           # ["app.log", ...] (no . / ..)
Dir["logs/*.log"]              # glob
Dir["**/*.rb"]                 # recursive glob
```

`Dir["pattern"]` is how Chapter 5's `plugins.rb` found every plugin file. Same pattern appears in Rails initializers, test suites, and Rack middleware stacks.

### CSV

```ruby
require "csv"

CSV.read("data.csv", headers: true)              # array of rows
CSV.foreach("data.csv", headers: true) do |row|  # streaming
  puts row["name"]
end

CSV.open("out.csv", "w") do |csv|
  csv << ["name", "age"]
  csv << ["Yosia", 30]
end
```

`read` for small files, `foreach` for big ones — same rule as `File`.

### `ensure` — always runs

```ruby
file = File.open("out.txt", "w")
begin
  file.write("hello")
ensure
  file.close
end
```

`ensure` runs whether the `begin` block succeeded, raised, or used `return`. It's for cleanup you must do no matter what. Most of the time the block form of `File.open` replaces it — cleaner, same guarantee.

### `raise` — three forms

```ruby
raise "something went wrong"                    # raises RuntimeError
raise ArgumentError, "name can't be empty"      # specific class
raise ArgumentError.new("name can't be empty")  # same thing, more verbose
```

Make your own hierarchy when there are multiple related errors:

```ruby
class AppError < StandardError; end
class NotFound < AppError; end
class Unauthorized < AppError; end
```

Callers can `rescue AppError` to catch anything, or `rescue NotFound` for the one case. Keep the tree shallow — two levels is usually enough.

### Debugging: `binding.irb` and Pry

Chapter 3 introduced live debugging. The same trick handles network and file code perfectly.

```ruby
def fetch_user(id)
  response = Net::HTTP.get_response(URI("..."))
  binding.irb           # drop into a REPL with `response` live
  JSON.parse(response.body)
end
```

Inside the REPL you can inspect `response`, try `response.body[0..100]`, retype the JSON.parse call with variations, and then `exit` to continue. This is much faster than `puts` debugging for network code — production APIs return surprising shapes and one live look beats ten printlns.

For a richer console with `ls`, `whereami`, `show-source`, and `show-doc`, `require "pry"` and use `binding.pry`. Add `pry-byebug` if you also want `step`/`next`/`finish`/`continue` in Pry. Pick one:

- `binding.irb` — built-in, zero setup.
- `binding.pry` — richer console, great for exploration.
- `require "debug"` + `binding.break` — the dedicated debugger.

## Common pitfalls

- **Bare `rescue` catches too much.** `rescue` with no class catches `StandardError`, which includes `ArgumentError`, `TypeError`, `NoMethodError` — bugs you wanted to crash on. Always name the class: `rescue Errno::ENOENT`, `rescue JSON::ParserError`. If you really want everything, write `rescue StandardError => e` so the intent is visible.
- **`ENV["FOO"]` returns `nil` silently.** Forget to set the variable and the `nil` propagates until something far away blows up with `undefined method on NilClass`. Use `ENV.fetch("FOO")` (raises immediately) or `ENV.fetch("FOO", "default")` (explicit fallback). Never `ENV["FOO"]` for required values.
- **Not closing files.** `File.open(path, "w")` without a block leaves the file open until garbage collection — file handles leak, on Windows the file stays locked. Use the block form every time.
- **String keys when you wanted symbols.** `JSON.parse('{"a":1}')` returns `{"a"=>1}`. Calling `data[:a]` returns `nil`. Pass `symbolize_names: true` for config-shaped JSON. Leave string keys when the shape comes from outside.
- **Assuming network calls succeed.** `Net::HTTP.get` raises on DNS failure, `Net::OpenTimeout` on slow connect, `Errno::ECONNRESET` on drop, and returns 5xx as plain response objects. Wrap network calls in a bounded retry and check `response.is_a?(Net::HTTPSuccess)` before parsing the body.

## What you learned

| Concept | Key point |
|---|---|
| `File.read` / `foreach` / `readlines` | three ways to read |
| `File.write` / `File.open(p, "w") do \|f\|` | write, with safe close |
| `File.join` / `__dir__` / `__FILE__` | portable paths |
| `Dir["pattern"]` | glob files |
| `JSON.parse(s, symbolize_names: true)` | parse JSON to symbol-keyed hash |
| `JSON.pretty_generate(h)` | multi-line JSON output |
| `CSV.foreach(file, headers: true)` | streaming CSV with column names |
| `begin / rescue / ensure / retry` | exception handling |
| `raise Class, "msg"` | throw an exception |
| custom exception classes | so callers can catch by type |
| `ENV.fetch(name)` / `ENV.fetch(name, default)` | required-or-default |
| `Net::HTTP.get_response(uri)` | minimal HTTP GET |
| `response.is_a?(Net::HTTPSuccess)` | the way to test for 2xx |
| `.freeze` | prevent mutation of constants |
| `Set` | fast "have I seen this?" |
| `binding.irb` / `binding.pry` | interactive debugging, anywhere |

## Going deeper

- Read the `IO` and `StringIO` docs at `https://docs.ruby-lang.org/en/master/IO.html` and `.../StringIO.html`. `File` is an `IO` with a path; `StringIO` is an in-memory `IO` you can hand to anything that expects a file. Tests get easier once you see this.
- Read `OpenStruct` (`require "ostruct"`) — the standard library's version of Chapter 6's `Flex`. Compare its source to yours. That's what production-grade `method_missing` looks like.
- Read the source of the `dotenv` gem: one short file that does what Exercise 6 asks. Then read `httparty`: a thin layer over `Net::HTTP` that adds the conveniences this chapter's `HttpClient` skips. Reading small gems is the fastest way to graduate from "I write scripts" to "I ship libraries."

## Exercises

1. **safe_read.rb**: write a helper `safe_read(path)` that returns the file contents, or `""` if the file doesn't exist or is unreadable. Log a warning on failure to STDERR. Starter: `exercises/1_safe_read.rb`.

2. **logwatch with rotation**: extend `logwatch.rb` to handle log rotation — when the file shrinks (because it was truncated/replaced), reset and re-scan from the beginning. Hint: track `File.size`. Starter: `exercises/2_logwatch_rotation.rb`.

3. **config_loader: required keys**: add a `required:` argument to `Config.load`. If any required key resolves to `nil` after layering, raise `MissingKey`. Starter: `exercises/3_config_required.rb`.

4. **HTTP retry with backoff**: extend `with_retry` to add exponential backoff — wait `0.5`, `1.0`, `2.0` seconds between retries. Starter: `exercises/4_http_backoff.rb`.

5. **Custom error hierarchy**: build a small hierarchy: `AppError < StandardError`, `NotFound < AppError`, `Unauthorized < AppError`, `BadRequest < AppError`. Each takes a message in its initializer. Write a function that demonstrates catching the base vs the leaves. Starter: `exercises/5_error_hierarchy.rb`.

6. **dotenv-lite**: write `dotenv.rb` that reads a `.env` file (KEY=value per line, comments start with `#`) and sets each into `ENV`. Skip blank lines. Starter: `exercises/6_dotenv.rb`.
