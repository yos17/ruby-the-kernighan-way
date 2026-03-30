# Chapter 12 — Gems and the Standard Library

## The Standard Library — What's Already There

Ruby ships with a rich standard library. You don't need gems for most common tasks.

```ruby
# JSON
require 'json'
JSON.parse('{"name":"Yosia","age":30}')   # => {"name"=>"Yosia", "age"=>30}
{ name: "Yosia" }.to_json                 # => '{"name":"Yosia"}'

# CSV
require 'csv'
CSV.foreach("data.csv", headers: true) { |row| puts row["name"] }
CSV.generate { |csv| csv << ["Alice", 30]; csv << ["Bob", 25] }

# Date and Time
require 'date'
Date.today                          # => #<Date: 2026-03-28>
Date.parse("2026-01-15")           # => #<Date: 2026-01-15>
Date.today + 30                    # 30 days from now
Time.now.strftime("%Y-%m-%d %H:%M:%S")

# HTTP (built-in, no gems needed for simple cases)
require 'net/http'
require 'uri'
response = Net::HTTP.get(URI("https://api.github.com/users/yos17"))
data = JSON.parse(response)

# URI
require 'uri'
uri = URI("https://example.com/path?key=value")
uri.host    # => "example.com"
uri.path    # => "/path"
uri.query   # => "key=value"

# Digest (hashing)
require 'digest'
Digest::MD5.hexdigest("hello")      # => "5d41402abc4b2a76b9719d911017c592"
Digest::SHA256.hexdigest("hello")   # => "2cf24dba..."

# SecureRandom (for tokens, IDs)
require 'securerandom'
SecureRandom.hex(32)      # 64-char hex string
SecureRandom.uuid         # "110e8400-e29b-41d4-a716-446655440000"
SecureRandom.base64(24)   # random base64 string

# Open3 (run shell commands, capture output)
require 'open3'
stdout, stderr, status = Open3.capture3("ls -la /tmp")
puts stdout
puts "Exit code: #{status.exitstatus}"

# Benchmark
require 'benchmark'
Benchmark.bm do |x|
  x.report("Array#include?") { 1000.times { [1,2,3,4,5].include?(3) } }
  x.report("Set#include?")   { require 'set'; s = Set[1,2,3,4,5]; 1000.times { s.include?(3) } }
end
```

---

## Gems — Third-Party Libraries

A gem is a packaged Ruby library. The gem ecosystem is huge.

```bash
gem install httparty          # install
gem list                      # list installed gems
gem search rails              # search
gem uninstall httparty        # remove
```

### Bundler — Managing Gem Dependencies

```ruby
# Gemfile
source "https://rubygems.org"

gem "httparty"                # latest
gem "pry", "~> 0.14"         # ~> means: >= 0.14, < 0.15
gem "rspec", ">= 3.0"        # any version >= 3.0
gem "sqlite3", require: false # don't auto-require
```

```bash
bundle install        # install all gems in Gemfile
bundle exec ruby app.rb  # run with Gemfile gems
bundle update httparty    # update one gem
```

---

## Essential Gems to Know

### HTTParty — Simple HTTP requests
```ruby
require 'httparty'

response = HTTParty.get("https://api.github.com/users/yos17")
user = JSON.parse(response.body)
puts "Repos: #{user['public_repos']}"

# POST with JSON body
response = HTTParty.post("https://api.example.com/posts",
  headers: { "Content-Type" => "application/json" },
  body: { title: "Hello", body: "World" }.to_json
)
```

### Faraday — More powerful HTTP
```ruby
require 'faraday'

conn = Faraday.new(url: "https://api.github.com") do |f|
  f.request  :json
  f.response :json
end

response = conn.get("/users/yos17")
puts response.body["public_repos"]
```

### Thor — Building CLI tools
```ruby
require 'thor'

class MyCLI < Thor
  desc "greet NAME", "Greet someone"
  option :loud, type: :boolean
  def greet(name)
    msg = "Hello, #{name}!"
    puts options[:loud] ? msg.upcase : msg
  end

  desc "count FILE", "Count words in a file"
  def count(file)
    words = File.read(file).split.length
    puts "#{file}: #{words} words"
  end
end

MyCLI.start(ARGV)
```

### Rake — Task automation
```ruby
# Rakefile
task default: [:test]

task :test do
  puts "Running tests..."
  sh "ruby spec/all_tests.rb"
end

task :build do
  puts "Building..."
  sh "gem build myapp.gemspec"
end

namespace :db do
  task :migrate do
    puts "Running migrations..."
  end

  task :seed do
    puts "Seeding database..."
  end
end
```

```bash
rake           # runs default task
rake test      # specific task
rake db:seed   # namespaced task
```

---

## Your Program: A CLI Tool

```ruby
#!/usr/bin/env ruby
# mkproject — create a new project with standard structure
# Usage: mkproject my-app [--type web|cli|gem]

require 'optparse'
require 'fileutils'

options = { type: "cli" }
OptionParser.new do |opts|
  opts.banner = "Usage: mkproject [options] name"
  opts.on("--type TYPE", %w[web cli gem], "Project type (web/cli/gem)") do |t|
    options[:type] = t
  end
end.parse!

name = ARGV.first
unless name
  puts "Error: project name required"
  exit 1
end

base = File.join(Dir.pwd, name)
if File.exist?(base)
  puts "Error: #{name} already exists"
  exit 1
end

puts "Creating #{options[:type]} project: #{name}"

# Create structure
dirs = ["lib", "spec", "bin"]
dirs << "app/controllers" << "app/models" << "app/views" if options[:type] == "web"

dirs.each do |dir|
  FileUtils.mkdir_p(File.join(base, dir))
end

# Create files
files = {
  "README.md"     => "# #{name}\n\n## Setup\n\n```bash\nbundle install\n```\n",
  "Gemfile"       => "source \"https://rubygems.org\"\n\ngem \"rspec\", \"~> 3.0\"\n",
  ".gitignore"    => "*.gem\n.bundle/\nvendor/\n",
  "lib/#{name.gsub('-','_')}.rb" => "module #{name.split('-').map(&:capitalize).join}\nend\n",
  "spec/#{name.gsub('-','_')}_spec.rb" => "require_relative '../lib/#{name.gsub('-','_')}'\n\nRSpec.describe #{name.split('-').map(&:capitalize).join} do\n  it 'works' do\n    expect(true).to be true\n  end\nend\n"
}

files.each do |path, content|
  full_path = File.join(base, path)
  FileUtils.mkdir_p(File.dirname(full_path))
  File.write(full_path, content)
end

# Initialize git
system("git init #{base} -q")
system("cd #{base} && git add . && git commit -m 'Initial commit' -q")

puts "✅ Created #{name}/"
puts "   cd #{name} && bundle install"
```

---

## Exercises

1. Write a gem `wordtools` with `bin/wordtools` CLI that wraps all the tools from Ch4
2. Write a `Rakefile` for the Ruby Software Tools project with tasks: `test`, `install`, `clean`
3. Build a CLI that fetches your GitHub repos and shows them in a table
4. Publish your gem to rubygems.org (a real gem you built in this course)

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| Standard library | `json`, `csv`, `net/http`, `digest`, `benchmark` — no gems needed |
| Gems | third-party libraries — install with `gem install` |
| Bundler | manages gem versions per project via `Gemfile` |
| `Gemfile` | list of dependencies |
| `bundle exec` | run with exact gem versions from Gemfile |
| Thor | build CLI tools with commands and options |
| Rake | task automation (like make, but Ruby) |
