# Chapter 12 — Gems and the Standard Library

By this point, an easy beginner mistake is to assume every new problem needs a gem.

Often it does not.

This chapter matters because strong Ruby programmers learn to ask two questions in this order:

1. is this already in the standard library?
2. if not, which gem solves it well?

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

A gem is just a packaged Ruby library someone else published for reuse.

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

Do not feel pressure to memorize this whole section. The main beginner goal is to understand the role gems play and to become comfortable installing and using a few common ones.

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

---

## Solutions

### Exercise 1

```ruby
# wordtools gem structure
# A gem that wraps all the text tools from Ch4

# Directory layout:
# wordtools/
# ├── bin/
# │   └── wordtools
# ├── lib/
# │   ├── wordtools.rb
# │   └── wordtools/
# │       ├── stats.rb
# │       ├── anagram.rb
# │       └── nato.rb
# ├── spec/
# │   └── wordtools_spec.rb
# ├── wordtools.gemspec
# └── Gemfile

# --- bin/wordtools ---
#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/wordtools"

WordTools::CLI.start(ARGV)

# --- lib/wordtools.rb ---
require_relative "wordtools/stats"
require_relative "wordtools/anagram"
require_relative "wordtools/nato"
require_relative "wordtools/cli"

module WordTools
  VERSION = "0.1.0"
end

# --- lib/wordtools/cli.rb ---
require 'optparse'

module WordTools
  class CLI
    def self.start(args)
      command = args.shift

      case command
      when "stats"
        numbers = args.map(&:to_f)
        puts Stats.analyze(numbers)
      when "anagram"
        puts Anagram.check?(args[0], args[1])
      when "nato"
        puts NATO.encode(args.join(" "))
      when nil, "--help", "-h"
        puts <<~HELP
          wordtools - Text utility toolbox

          Usage: wordtools <command> [args]

          Commands:
            stats  <num1> <num2> ...   Statistical analysis of numbers
            anagram <word1> <word2>    Check if two words are anagrams
            nato <text>                Encode text as NATO phonetic alphabet

          Examples:
            wordtools stats 1 2 3 4 5
            wordtools anagram listen silent
            wordtools nato SOS
        HELP
      else
        puts "Unknown command: #{command}"
        exit 1
      end
    end
  end
end

# --- lib/wordtools/stats.rb ---
module WordTools
  module Stats
    def self.analyze(numbers)
      return "No numbers provided" if numbers.empty?

      sorted = numbers.sort
      count  = numbers.length
      sum    = numbers.sum
      mean   = sum / count

      median = count.odd? ? sorted[count / 2] :
               (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0

      <<~STATS
        Count:  #{count}
        Min:    #{numbers.min}
        Max:    #{numbers.max}
        Sum:    #{sum}
        Mean:   #{mean.round(4)}
        Median: #{median}
      STATS
    end
  end
end

# --- wordtools.gemspec ---
Gem::Specification.new do |spec|
  spec.name        = "wordtools"
  spec.version     = "0.1.0"
  spec.summary     = "Text utility toolbox"
  spec.description = "CLI and library for text stats, anagram checking, and NATO alphabet"
  spec.authors     = ["Your Name"]
  spec.email       = ["you@example.com"]
  spec.homepage    = "https://github.com/yourname/wordtools"
  spec.license     = "MIT"

  spec.files         = Dir["lib/**/*.rb", "bin/*", "README.md"]
  spec.bindir        = "bin"
  spec.executables   = ["wordtools"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_development_dependency "rspec", "~> 3.0"
end

# Build and install:
# gem build wordtools.gemspec
# gem install wordtools-0.1.0.gem
```

### Exercise 2

```ruby
# Rakefile for the Ruby Software Tools project

require 'rake/clean'

# Files to clean up
CLEAN.include("**/*.gem", "tmp/", "coverage/")

# Default task
task default: [:test]

desc "Run all tests"
task :test do
  ruby_files = Dir["spec/**/*_spec.rb"]
  if ruby_files.empty?
    puts "No spec files found. Looking for test files..."
    ruby_files = Dir["test/**/*_test.rb"]
  end

  if ruby_files.empty?
    puts "No test files found."
  else
    ruby_files.each do |f|
      puts "Running #{f}..."
      sh "ruby #{f}"
    end
  end
end

desc "Install dependencies"
task :install do
  sh "bundle install"
end

desc "Clean generated files"
task :clean do
  sh "rm -rf *.gem tmp/ coverage/"
  puts "Cleaned."
end

desc "Build gem"
task :build do
  gemspec = Dir["*.gemspec"].first
  if gemspec
    sh "gem build #{gemspec}"
    puts "Gem built successfully."
  else
    puts "No .gemspec found."
    exit 1
  end
end

desc "Run linter (rubocop)"
task :lint do
  sh "bundle exec rubocop" rescue puts "rubocop not installed — run: gem install rubocop"
end

desc "Show project stats"
task :stats do
  rb_files = Dir["lib/**/*.rb", "bin/*"]
  total_lines = rb_files.sum { |f| File.readlines(f).length }
  puts "Ruby files: #{rb_files.length}"
  puts "Total lines: #{total_lines}"
end

namespace :chapter do
  Dir["chapters/*/"].each do |dir|
    name = File.basename(dir)
    desc "Run examples from #{name}"
    task name do
      Dir["#{dir}*.rb"].each { |f| sh "ruby #{f}" rescue nil }
    end
  end
end
```

### Exercise 3

```ruby
# github_repos.rb — fetch your GitHub repos and show them in a table
# Usage: ruby github_repos.rb USERNAME

require 'net/http'
require 'uri'
require 'json'

username = ARGV[0]

unless username
  puts "Usage: github_repos.rb USERNAME"
  exit 1
end

puts "Fetching repos for @#{username}..."

uri = URI("https://api.github.com/users/#{username}/repos?per_page=100&sort=updated")
request = Net::HTTP::Get.new(uri)
request["User-Agent"] = "ruby-kernighan-way/1.0"
request["Accept"]     = "application/vnd.github.v3+json"

# Add token if available (avoids rate limiting)
if (token = ENV["GITHUB_TOKEN"])
  request["Authorization"] = "Bearer #{token}"
end

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end

if response.code != "200"
  puts "Error: #{response.code} #{response.message}"
  puts JSON.parse(response.body)["message"] rescue nil
  exit 1
end

repos = JSON.parse(response.body)

if repos.empty?
  puts "No public repositories found."
  exit 0
end

# Sort by stars descending
repos = repos.sort_by { |r| -r["stargazers_count"] }

# Table formatting
name_width  = [repos.map { |r| r["name"].length }.max, 30].min
desc_width  = 40
total_width = name_width + desc_width + 30

puts "\n#{"Repository".ljust(name_width)}  #{"Stars".rjust(6)}  #{"Forks".rjust(5)}  #{"Language".ljust(12)}  Description"
puts "-" * total_width

repos.each do |repo|
  name     = repo["name"].ljust(name_width)
  stars    = repo["stargazers_count"].to_s.rjust(6)
  forks    = repo["forks_count"].to_s.rjust(5)
  lang     = (repo["language"] || "—").ljust(12)
  desc     = (repo["description"] || "").slice(0, desc_width)

  puts "#{name}  #{stars}  #{forks}  #{lang}  #{desc}"
end

puts "\n#{repos.length} repositories"
puts "Total stars: #{repos.sum { |r| r['stargazers_count'] }}"
```

### Exercise 4

```
# How to publish a gem to rubygems.org

# 1. Create an account at https://rubygems.org/sign_up

# 2. Make sure your .gemspec is complete and valid:
#    - name, version, summary, authors, email
#    - files: include all needed files
#    - homepage and license set

# 3. Build the gem:
gem build wordtools.gemspec
# => wordtools-0.1.0.gem

# 4. Authenticate with RubyGems:
gem signin
# Enter your RubyGems.org credentials

# Or set up API key:
curl -u you@example.com https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials
chmod 0600 ~/.gem/credentials

# 5. Push to RubyGems.org:
gem push wordtools-0.1.0.gem
# => Pushing gem to https://rubygems.org...
# => Successfully registered gem: wordtools (0.1.0)

# 6. Verify:
gem info wordtools
# Or visit: https://rubygems.org/gems/wordtools

# 7. Install it from anywhere:
gem install wordtools

# Notes:
# - Gem names must be unique on rubygems.org
# - Use semantic versioning: MAJOR.MINOR.PATCH
# - Add a CHANGELOG.md to document versions
# - Add a LICENSE file (MIT is common)
# - Tag the release in git: git tag v0.1.0 && git push --tags

# Yanking a bad release (emergency only):
# gem yank wordtools -v 0.1.0
```
