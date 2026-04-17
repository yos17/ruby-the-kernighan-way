# Chapter 7 — Files, Errors, the Outside World

The previous chapters stayed mostly inside Ruby. This chapter is about the places where programs touch the world and the world pushes back. Files are missing. JSON is malformed. Servers time out. Environment variables are unset. That is ordinary programming, not an edge case.

The three programs set the pace: `logwatch.rb` reads a changing file, `config_loader.rb` layers defaults with outside input, and `tiny_http_client.rb` talks to a remote server without pretending the network is polite.

## Reading files

You've used `File.foreach` and `File.read`. The full picture:

```ruby
File.read("notes.txt")            # whole file as one string
File.readlines("notes.txt")       # array of lines (with \n)
File.readlines("notes.txt", chomp: true)   # array of lines (without \n)
File.foreach("notes.txt") { |line| puts line }   # streaming
File.exist?("notes.txt")          # => true / false
File.size("notes.txt")            # bytes
File.mtime("notes.txt")           # Time of last modification
```

Use `foreach` for any file that might be large — it doesn't load the whole thing into memory.

## Writing files

```ruby
File.write("out.txt", "first line\nsecond line\n")    # whole file
File.write("out.txt", "appended\n", mode: "a")        # append

# For multiple writes, open in a block:
File.open("out.txt", "w") do |f|
  f.puts "line 1"
  f.puts "line 2"
end
# File auto-closes when the block exits (even on exception)
```

`File.open(path, mode) do |f| ... end` is the safe form — Ruby closes the file even if your block raises.

The mode strings:

- `"r"` — read (default)
- `"w"` — write (truncates the file first)
- `"a"` — append (creates if missing)
- `"r+"` — read+write
- `"wb"` / `"rb"` — binary mode (matters on Windows)

## Paths

Build paths portably. Don't hard-code `/`:

```ruby
File.join("data", "users", "yosia.json")
# => "data/users/yosia.json"  on Unix
# => "data\users\yosia.json"  on Windows

File.basename("/tmp/foo.rb")      # => "foo.rb"
File.dirname("/tmp/foo.rb")       # => "/tmp"
File.extname("/tmp/foo.rb")       # => ".rb"

__FILE__       # the current source file
__dir__        # directory of the current source file
```

`File.join(__dir__, "data.json")` is the standard way to load a file *next to the script*, regardless of where the user runs it from.

## Directories

```ruby
Dir.exist?("logs")
Dir.mkdir("logs")           # one level
FileUtils.mkdir_p("a/b/c")  # nested (require "fileutils")
Dir.entries("logs")         # ["..", ".", "app.log", ...]
Dir.children("logs")        # ["app.log", ...]      (no . / ..)
Dir["logs/*.log"]           # glob: ["logs/app.log", "logs/db.log"]
Dir["**/*.rb"]              # recursive: every .rb under the current dir
```

## JSON

Ruby has a built-in JSON parser:

```ruby
require "json"

# Parse
data = JSON.parse('{"name": "Yosia", "age": 30}')
# => {"name" => "Yosia", "age" => 30}

# Symbol keys (often what you want)
JSON.parse('{"name": "Yosia"}', symbolize_names: true)
# => {name: "Yosia"}

# Generate
{ name: "Yosia", age: 30 }.to_json     # => '{"name":"Yosia","age":30}'
JSON.pretty_generate({ name: "Yosia" }) # multi-line, indented
```

Use `symbolize_names: true` for config-shaped data. For data that round-trips through external systems (where the keys came from JSON), keeping string keys avoids surprises.

## CSV

You met CSV in Chapter 2. The full set:

```ruby
require "csv"

# Read
CSV.read("data.csv")                  # array of arrays
CSV.read("data.csv", headers: true)   # array of CSV::Row (acts like a hash)

# Stream (large files)
CSV.foreach("data.csv", headers: true) do |row|
  puts row["name"]
end

# Write
CSV.open("out.csv", "w") do |csv|
  csv << ["name", "age"]
  csv << ["Yosia", 30]
end

# Generate as a string
csv_str = CSV.generate do |csv|
  csv << ["name", "age"]
  csv << ["Yosia", 30]
end
```

## Exceptions: begin / rescue / ensure

Things go wrong. Code that handles them gracefully:

```ruby
begin
  data = File.read(path)
rescue Errno::ENOENT
  puts "no such file: #{path}"
  data = ""
rescue Errno::EACCES
  puts "permission denied"
  data = ""
end
```

Multiple `rescue` clauses match by class. The first match wins. Catch the *narrowest* exception class you can. `rescue` with no class catches `StandardError`, which is usually broader than you want.

```ruby
begin
  risky_thing
rescue StandardError => e
  puts "failed: #{e.message}"
  puts e.backtrace.first(5)
end
```

`ensure` runs whether the begin block succeeds or raises — used for cleanup (close files, release locks, restore state):

```ruby
file = File.open("out.txt", "w")
begin
  file.write("hello")
ensure
  file.close
end
# But just use File.open with a block — same thing, less code.
```

`retry` re-runs the begin block. Combine with a counter to bound the attempts:

```ruby
attempts = 0
begin
  attempts += 1
  flaky_network_call
rescue Net::OpenTimeout
  retry if attempts < 3
  raise
end
```

## raise — throwing exceptions

```ruby
raise "something went wrong"                   # raises RuntimeError
raise ArgumentError, "name can't be empty"     # raises a specific class
raise ArgumentError.new("name can't be empty") # same thing, more verbose
```

Define your own exception classes for things that callers might want to catch separately:

```ruby
class ConfigError < StandardError; end
class MissingKey < ConfigError
  def initialize(key) = super("missing required key: #{key}")
end

raise MissingKey.new(:api_token)
```

A small hierarchy lets callers `rescue ConfigError` to catch any config problem, or `rescue MissingKey` for just one kind. Keep it shallow — two levels is usually enough.

## ENV — environment variables

```ruby
ENV["DATABASE_URL"]            # => "postgres://..." or nil
ENV.fetch("DATABASE_URL")      # raises if missing
ENV.fetch("PORT", "3000")      # default if missing
ENV["DEBUG"] == "true"         # boolean from string
```

Use `ENV.fetch` — it tells you immediately if a required variable is missing, instead of `nil` propagating until something fails far away.

## Net::HTTP

Ruby's standard HTTP client. Verbose but always available, no gem required:

```ruby
require "net/http"
require "uri"

uri = URI("https://api.github.com/users/octocat")
response = Net::HTTP.get_response(uri)
puts response.code           # => "200"
puts response.body[0..100]   # first 100 chars

# JSON shorthand for GET
require "json"
data = JSON.parse(Net::HTTP.get(uri))
puts data["name"]

# POST with body and headers
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
req = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
req.body = { name: "test" }.to_json
res = http.request(req)
```

For real apps you'll usually reach for `httparty` or `faraday` (gems). For scripts and tools, `Net::HTTP` is enough.

## binding.irb

You met this in Ch 0 as part of "reading errors." Now use it for live debugging:

```ruby
def slope(p1, p2)
  binding.irb       # execution stops here; you drop into a REPL
  (p2.y - p1.y).to_f / (p2.x - p1.x)
end
```

When the program runs and reaches `binding.irb`, you get a prompt where every local variable is visible. Type expressions; see results. `step`, `next`, `continue` (added by the built-in `debug` gem on Ruby 3.3+) move through the program one call at a time.

This is the most underused feature in Ruby. Beats `puts` debugging in nearly every case.

If you want the standard debugger without any extra gems, `require "debug"` and use `binding.break` (or `debugger`) instead. That gives you the dedicated debug console directly.

## Pry

`binding.irb` is the built-in way. Pry is the richer console many Rubyists still prefer.

Install it:

```bash
gem install pry pry-doc pry-byebug
```

If you are working inside a Bundler app, put those in the `:development` group instead.

Then drop a breakpoint into the code:

```ruby
require "pry"

def slope(p1, p2)
  binding.pry
  (p2.y - p1.y).to_f / (p2.x - p1.x)
end
```

When execution stops, you are in the real scope of the method, just as with `binding.irb`. The useful Pry commands are different:

```text
ls                    # list methods and variables in scope
whereami              # show the current source around the breakpoint
show-source slope     # show a method's source
show-doc Array#map    # show documentation
cd p1                 # move the Pry context into an object
exit                  # leave Pry and continue the program
```

With `pry-byebug` installed, Pry also gets step-through commands:

```text
step
next
finish
continue
break 42
```

The split is simple:

- use `binding.irb` or `binding.break` when you want the built-in path
- use `binding.pry` when you want a better console for poking around objects, source, and docs
- add `pry-byebug` when you want to stay in Pry and still step line by line

Pry's strength is exploration. `cd`, `ls`, `show-source`, and `show-doc` make it feel less like a debugger and more like a live lab bench for the program in front of you.

## logwatch.rb

Tail a file and react to lines matching a pattern.

```ruby
# logwatch.rb — tail a file, alert when a pattern shows up
# Usage: ruby logwatch.rb <pattern> <file>

require "set"

pattern = Regexp.new(ARGV[0])
filename = ARGV[1]
abort "usage: logwatch.rb PATTERN FILE" unless pattern && filename

seen = Set.new
loop do
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

Run it in one terminal, then `echo "ERROR new failure" >> app.log` from another and watch the alert appear.

(File: `examples/logwatch.rb`. Test with `examples/app.log`.)

## config_loader.rb

A layered config: defaults overridden by a JSON file overridden by environment variables.

```ruby
# config_loader.rb — layered config (defaults < json < env)
# Usage: ruby config_loader.rb [config.json]

require "json"

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

class ConfigError < StandardError; end

if __FILE__ == $PROGRAM_NAME
  config = Config.load(ARGV[0])
  puts "config:"
  puts config
end
```

What's new.

`DEFAULTS = {...}.freeze` — the `freeze` makes the hash immutable. Anyone trying to mutate it gets a runtime error. Always freeze constants that hold mutable types (Hash, Array, String).

`each_with_object({}) do |key, h| ... end` — accumulate into the hash `h`, returning it.

`rescue JSON::ParserError => e` catches just that one error class, lets others propagate.

The class is layered — defaults < JSON < ENV. ENV always wins. This is the standard 12-Factor pattern.

Test:

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

(File: `examples/config_loader.rb`.)

## tiny_http_client.rb

A small HTTP client for JSON APIs.

```ruby
# tiny_http_client.rb — minimal HTTP client for JSON APIs
# Usage: ruby tiny_http_client.rb <url>

require "net/http"
require "uri"
require "json"

class HttpClient
  class HttpError < StandardError
    attr_reader :status
    def initialize(status, message) = (@status = status; super(message))
  end

  def initialize(base_url) = @base_url = base_url

  def get(path)
    uri = URI.join(@base_url, path)
    response = with_retry { Net::HTTP.get_response(uri) }
    raise HttpError.new(response.code.to_i, response.body) unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body, symbolize_names: true)
  end

  private

  def with_retry(max: 3, &block)
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
  end
end
```

What's new.

`URI.join(base, path)` resolves a relative path against a base URL.

The custom `HttpError` class carries a `status` attribute. Callers can `rescue HttpError` and inspect the status.

`with_retry` wraps a block with bounded retry on transient network errors. The pattern (counter + bounded retry + final raise) is one to memorize.

(File: `examples/tiny_http_client.rb`. Requires network access to test.)

## Common pitfalls

- **Bare `rescue` catches too much.** `rescue` with no class catches `StandardError`, which includes `ArgumentError`, `TypeError`, `NoMethodError` — bugs you wanted to crash on. Always name the class: `rescue Errno::ENOENT`, `rescue JSON::ParserError`. If you really do want everything, write `rescue StandardError => e` so the intent is on the page.
- **`ENV["FOO"]` returns `nil` silently.** Forget to set the variable and `nil` propagates until something far away blows up with `undefined method on NilClass`. Use `ENV.fetch("FOO")` (raises immediately) or `ENV.fetch("FOO", "default")` (explicit fallback). Never `ENV["FOO"]` for required values.
- **Not closing files.** `File.open(path, "w")` without a block leaves the file open until garbage collection — file handles leak, on Windows the file stays locked. Use the block form: `File.open(path, "w") { |f| f.puts(...) }`. Ruby closes it for you, even on exception.
- **String keys when you wanted symbols.** `JSON.parse('{"a": 1}')` returns `{"a" => 1}`. Calling `data[:a]` returns `nil`. Pass `symbolize_names: true` when the keys are config-shaped and you control the JSON. Leave string keys when the JSON came from an external system you do not control.
- **Assuming network calls succeed.** `Net::HTTP.get` raises on DNS failure, `Net::OpenTimeout` on slow connect, `Errno::ECONNRESET` on a dropped connection, and returns 5xx responses as success objects. Wrap any network call in `with_retry` (counter + bounded retry + final `raise`) and check `response.is_a?(Net::HTTPSuccess)` before parsing the body.

## What you learned

| Concept | Key point |
|---|---|
| `File.read` / `foreach` / `readlines` | three ways to read |
| `File.write` / `File.open(p, "w") do \|f\|` | write, with safe close |
| `File.join`, `__dir__` | portable paths |
| `Dir["pattern"]` | glob files |
| `JSON.parse(s, symbolize_names: true)` | parse JSON to symbol-keyed hash |
| `JSON.pretty_generate(h)` | multi-line JSON output |
| `CSV.foreach(file, headers: true)` | streaming CSV with column names |
| `begin / rescue / ensure / retry` | exception handling |
| `raise Class, "msg"` / `raise Class.new(...)` | throw an exception |
| custom exception classes | so callers can catch them by type |
| `ENV.fetch(name)` / `ENV.fetch(name, default)` | env vars, with required-or-default semantics |
| `Net::HTTP.get_response(uri)` | minimal HTTP GET |
| `binding.irb` | interactive REPL at any point in your code |
| `binding.pry` + `pry-byebug` | richer console plus step-through debugging |

## Going deeper

- Read the `IO` and `StringIO` docs at `https://docs.ruby-lang.org/en/master/IO.html` and `https://docs.ruby-lang.org/en/master/StringIO.html`. `File` is just an `IO` with a path; `StringIO` is an in-memory `IO` you can hand to anything that wants a file. Tests get easier once you see this.
- Read `OpenStruct` (`require "ostruct"`). It is the standard library's `Flex` from this chapter. Compare its source to yours. Notice what production-grade `method_missing` looks like.
- Read the Pry README: `https://github.com/pry/pry`. Then read the `ruby/debug` README: `https://github.com/ruby/debug`. They represent the two Ruby debugging styles worth knowing: rich live console and dedicated debugger.
- Read the source of `dotenv` (the gem): one short file that does what Ch 7's exercise 6 asks. Then read `httparty`: a thin layer over `Net::HTTP` that adds the conveniences this chapter's `HttpClient` skips. Reading small gems is the fastest way to graduate from "I write scripts" to "I ship libraries."

## Exercises

1. **safe_read.rb**: write a helper `safe_read(path)` that returns the file contents, or `""` if the file doesn't exist or is unreadable. Log a warning on failure to STDERR. Starter: `exercises/1_safe_read.rb`.

2. **logwatch with rotation**: extend `logwatch.rb` to handle log rotation — when the file shrinks (because it was truncated/replaced), reset and re-scan from the beginning. Hint: track `File.size`. Starter: `exercises/2_logwatch_rotation.rb`.

3. **config_loader: required keys**: add a `required:` argument to `Config.load`. If any required key resolves to `nil` after layering, raise `MissingKey`. Starter: `exercises/3_config_required.rb`.

4. **HTTP retry with backoff**: extend `with_retry` to add exponential backoff — wait `0.5`, `1.0`, `2.0` seconds between retries. Starter: `exercises/4_http_backoff.rb`.

5. **Custom error hierarchy**: build a small hierarchy: `AppError < StandardError`, `NotFound < AppError`, `Unauthorized < AppError`, `BadRequest < AppError`. Each takes a message in its initializer. Write a function that demonstrates catching the base vs the leaves. Starter: `exercises/5_error_hierarchy.rb`.

6. **dotenv-lite**: write `dotenv.rb` that reads a `.env` file (KEY=value per line, comments start with `#`) and sets each into `ENV`. Skip blank lines. Starter: `exercises/6_dotenv.rb`.
