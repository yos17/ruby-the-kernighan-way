# Chapter 8 — I/O and Files

This chapter is more practical than it may first appear.

A huge amount of scripting work is really just:

- read a file
- transform the contents
- write a result somewhere else

So file I/O is not side knowledge. It is central tool-building knowledge.

## Reading Files

```ruby
# Read the whole file at once (fine for small files)
content = File.read("file.txt")

# Read into an array of lines
lines = File.readlines("file.txt")         # includes \n
lines = File.readlines("file.txt", chomp: true)  # strips \n

# Read line by line (memory efficient for large files)
File.foreach("file.txt") do |line|
  puts line.chomp
end

# With line numbers:
File.foreach("file.txt").with_index(1) do |line, num|
  puts "#{num}: #{line.chomp}"
end

# Read binary file
data = File.binread("image.png")
```

---

## Writing Files

A helpful beginner question is: am I replacing the file, or adding to it?

That one question usually tells you whether you want write mode or append mode.

```ruby
# Write (creates or overwrites)
File.write("output.txt", "Hello, World!\n")

# Open for writing
File.open("output.txt", "w") do |f|
  f.puts "Line 1"
  f.puts "Line 2"
  f.write "Line 3\n"
  f.print "Line 4\n"
end

# Append
File.open("log.txt", "a") do |f|
  f.puts "[#{Time.now}] Something happened"
end

# File automatically closed when block ends
# Without block, must close manually:
f = File.open("file.txt", "w")
f.puts "hello"
f.close    # don't forget!
```

---

## File and Path Operations

```ruby
# File info
File.exist?("file.txt")     # => true/false
File.file?("file.txt")      # true if regular file
File.directory?("dir")      # true if directory
File.size("file.txt")       # => bytes
File.zero?("empty.txt")     # true if empty
File.readable?("file.txt")
File.writable?("file.txt")

# Path manipulation
File.basename("/a/b/c.txt")       # => "c.txt"
File.basename("/a/b/c.txt", ".txt")  # => "c"
File.extname("/a/b/c.txt")        # => ".txt"
File.dirname("/a/b/c.txt")        # => "/a/b"
File.join("a", "b", "c.txt")      # => "a/b/c.txt"  (OS-aware /)
File.expand_path("~/Projects")    # => "/Users/yosia/Projects"
File.expand_path("../lib", __FILE__)  # relative to current file

# Time
File.mtime("file.txt")    # modification time
File.ctime("file.txt")    # change time
File.atime("file.txt")    # last access time
```

---

## Directories

```ruby
# List contents
Dir.entries(".")         # => [".", "..", "file1.txt", ...]
Dir.children(".")        # => ["file1.txt", ...] (no . and ..)
Dir["*.rb"]              # => all .rb files (glob)
Dir["**/*.rb"]           # => recursive glob

# Create and remove
Dir.mkdir("new_dir")
Dir.mkdir("deep/nested/dir")   # fails if parents don't exist
FileUtils.mkdir_p("deep/nested/dir")  # creates parents too

Dir.rmdir("empty_dir")
FileUtils.rm_rf("dir_and_contents")   # dangerous! no undo

# Current directory
Dir.pwd         # => "/Users/yosia/Projects"
Dir.chdir("/tmp") { puts Dir.pwd }   # change for block only

# Temp directory
require 'tmpdir'
Dir.mktmpdir do |dir|
  File.write("#{dir}/temp.txt", "temp content")
  puts "Temp file in: #{dir}"
end  # directory automatically deleted after block
```

---

## Pathname — Object-Oriented File Paths

If `File` functions feel a bit scattered, `Pathname` can feel cleaner because the path becomes an object you can ask questions of.

```ruby
require 'pathname'

p = Pathname.new("/Users/yosia/Projects/app.rb")

p.basename         # => #<Pathname:app.rb>
p.dirname          # => #<Pathname:/Users/yosia/Projects>
p.extname          # => ".rb"
p.exist?           # => true/false
p.file?
p.directory?

# Joining paths
home = Pathname.new(ENV["HOME"])
proj = home / "Projects" / "my-app"   # => uses / operator!
proj.mkpath                           # mkdir -p

# Read/write like File
proj.join("README.md").write("# My App")
content = proj.join("README.md").read
```

---

## StringIO — In-Memory IO

```ruby
require 'stringio'

# Use StringIO when you need an IO-compatible object but don't want a file
buf = StringIO.new
buf.puts "Line 1"
buf.puts "Line 2"
buf.string   # => "Line 1\nLine 2\n"

# Redirect stdout to a string:
output = StringIO.new
$stdout = output
puts "This goes to the string, not the screen"
$stdout = STDOUT
output.string   # => "This goes to the string, not the screen\n"

# Useful for testing
def process(io)
  io.each_line { |line| puts line.upcase }
end

process(StringIO.new("hello\nworld"))
```

---

## Your Program: Log File Processor

```ruby
# log_processor.rb — analyze log files
# Usage: ruby log_processor.rb app.log [--errors] [--stats] [--tail 20]

require 'optparse'
require 'time'

options = { errors_only: false, stats: false, tail: nil }
OptionParser.new do |opts|
  opts.banner = "Usage: log_processor.rb [options] logfile"
  opts.on("--errors",    "Show only errors")     { options[:errors_only] = true }
  opts.on("--stats",     "Show statistics")       { options[:stats] = true }
  opts.on("--tail N", Integer, "Show last N lines") { |n| options[:tail] = n }
end.parse!

file = ARGV.first
unless file && File.exist?(file)
  puts "File not found: #{file}"
  exit 1
end

# Parse log lines — format: [LEVEL] timestamp message
LogEntry = Struct.new(:level, :time, :message, :raw)

entries = []
File.foreach(file) do |line|
  if line =~ /\[(DEBUG|INFO|WARN|ERROR|FATAL)\]\s+(\S+)\s+(.*)/
    entries << LogEntry.new($1, $2, $3.chomp, line.chomp)
  else
    entries << LogEntry.new("INFO", "", line.chomp, line.chomp)
  end
end

# Apply filters
if options[:errors_only]
  entries = entries.select { |e| %w[ERROR FATAL].include?(e.level) }
end

if options[:tail]
  entries = entries.last(options[:tail])
end

# Output
if options[:stats]
  counts = entries.group_by(&:level).transform_values(&:count)
  puts "=== Log Statistics ==="
  puts "Total entries: #{entries.length}"
  %w[DEBUG INFO WARN ERROR FATAL].each do |level|
    n = counts[level] || 0
    next if n == 0
    pct = (n.to_f / entries.length * 100).round(1)
    bar = "█" * (n * 30 / entries.length)
    color = case level
            when "ERROR", "FATAL" then "\e[31m"
            when "WARN"  then "\e[33m"
            when "INFO"  then "\e[32m"
            else "\e[0m"
            end
    puts "#{color}#{level.ljust(6)}\e[0m #{n.to_s.rjust(6)} (#{pct.to_s.rjust(5)}%) #{bar}"
  end
else
  entries.each do |e|
    color = case e.level
            when "ERROR", "FATAL" then "\e[31m"
            when "WARN"  then "\e[33m"
            when "INFO"  then "\e[32m"
            else "\e[0m"
            end
    puts "#{color}#{e.raw}\e[0m"
  end
end
```

---

## Exercises

1. Write `find_duplicates.rb` that finds duplicate files in a directory tree (by content hash, not name)
2. Write `watch.rb` that monitors a file for new lines (like `tail -f`) and prints them as they appear
3. Build a simple key-value store backed by a JSON file: `store = KVStore.new("data.json"); store.set("key", "value"); store.get("key")`
4. Write `tree.rb` that prints a directory tree like the Unix `tree` command

---

## What You Learned

| Concept | Key point |
|---------|-----------|
| `File.read` | read whole file into string |
| `File.foreach` | read line by line (memory-safe) |
| `File.open("f","w")` | write mode — creates or overwrites |
| `File.open("f","a")` | append mode |
| Block form | file closed automatically at end of block |
| `File.exist?` / `.size` | file metadata |
| `File.join` | OS-portable path building |
| `Dir["**/*.rb"]` | recursive glob |
| `Pathname` | OO file path manipulation |
| `StringIO` | in-memory IO — same interface as a file |

---

## Solutions

### Exercise 1

```ruby
# find_duplicates.rb — find duplicate files by content hash
# Usage: ruby find_duplicates.rb [directory]

require 'digest'
require 'find'

dir = ARGV[0] || "."

unless File.directory?(dir)
  puts "Not a directory: #{dir}"
  exit 1
end

# Group files by their MD5 hash
file_hashes = Hash.new { |h, k| h[k] = [] }

Find.find(dir) do |path|
  next unless File.file?(path)
  next if File.size(path) == 0   # skip empty files

  hash = Digest::MD5.hexdigest(File.binread(path))
  file_hashes[hash] << path
end

# Report duplicates
duplicates = file_hashes.select { |_, paths| paths.length > 1 }

if duplicates.empty?
  puts "No duplicate files found in #{dir}"
else
  puts "Found #{duplicates.length} groups of duplicate files:\n"
  duplicates.each do |hash, paths|
    size = File.size(paths.first)
    puts "Hash: #{hash[0, 8]}...  Size: #{size} bytes"
    paths.each { |p| puts "  #{p}" }
    puts
  end
  total_wasted = duplicates.sum { |_, paths| File.size(paths.first) * (paths.length - 1) }
  puts "Total wasted space: #{total_wasted} bytes"
end
```

### Exercise 2

```ruby
# watch.rb — monitor a file for new lines (like tail -f)
# Usage: ruby watch.rb logfile.txt

file = ARGV[0]

unless file && File.exist?(file)
  puts "Usage: watch.rb <file>"
  exit 1
end

puts "Watching #{file} for changes (Ctrl+C to stop)..."
puts "-" * 50

# Start reading from the end of the file
pos = File.size(file)

begin
  loop do
    File.open(file) do |f|
      f.seek(pos)
      while (line = f.gets)
        print line
        pos = f.pos
      end
    end
    sleep 0.5   # check every half second
  end
rescue Interrupt
  puts "\nStopped watching."
end

# To test: run in one terminal, then in another:
#   echo "new log line" >> logfile.txt
```

### Exercise 3

```ruby
# kvstore.rb — simple key-value store backed by a JSON file

require 'json'
require 'fileutils'

class KVStore
  def initialize(path)
    @path = path
    @data = load
  end

  def set(key, value)
    @data[key.to_s] = value
    persist
    value
  end

  def get(key)
    @data[key.to_s]
  end

  def delete(key)
    value = @data.delete(key.to_s)
    persist
    value
  end

  def all
    @data.dup
  end

  def keys
    @data.keys
  end

  def exists?(key)
    @data.key?(key.to_s)
  end

  def clear
    @data.clear
    persist
    self
  end

  def size
    @data.size
  end

  def to_s
    "KVStore(#{@path}, #{@data.size} keys)"
  end

  private

  def load
    return {} unless File.exist?(@path)
    JSON.parse(File.read(@path))
  rescue JSON::ParserError
    {}
  end

  def persist
    FileUtils.mkdir_p(File.dirname(@path))
    File.write(@path, JSON.pretty_generate(@data))
  end
end

# Usage:
store = KVStore.new("/tmp/mystore.json")
store.set("user:1:name", "Yosia")
store.set("user:1:age", 30)
store.set("app:version", "1.0.0")

store.get("user:1:name")     # => "Yosia"
store.get("user:1:age")      # => 30
store.exists?("app:version") # => true
store.delete("user:1:age")
puts store.all.inspect
# => {"user:1:name"=>"Yosia", "app:version"=>"1.0.0"}
```

### Exercise 4

```ruby
# tree.rb — print a directory tree like the Unix `tree` command
# Usage: ruby tree.rb [directory] [--depth N]

require 'optparse'

options = { depth: Float::INFINITY, show_hidden: false }
OptionParser.new do |opts|
  opts.banner = "Usage: tree.rb [directory] [options]"
  opts.on("--depth N", Integer, "Max depth") { |n| options[:depth] = n }
  opts.on("--hidden",  "Show hidden files")  { options[:show_hidden] = true }
end.parse!

root = ARGV[0] || "."

unless File.directory?(root)
  puts "Not a directory: #{root}"
  exit 1
end

file_count = 0
dir_count  = 0

def print_tree(path, prefix: "", depth: Float::INFINITY, current_depth: 0,
               show_hidden: false, counts: { files: 0, dirs: 0 })
  return if current_depth > depth

  entries = Dir.children(path).sort
  entries.reject! { |e| e.start_with?(".") } unless show_hidden

  entries.each_with_index do |entry, i|
    full_path  = File.join(path, entry)
    is_last    = i == entries.length - 1
    connector  = is_last ? "└── " : "├── "
    extension  = is_last ? "    " : "│   "

    if File.directory?(full_path)
      counts[:dirs] += 1
      puts "#{prefix}#{connector}#{entry}/"
      print_tree(full_path,
                 prefix:        "#{prefix}#{extension}",
                 depth:         depth,
                 current_depth: current_depth + 1,
                 show_hidden:   show_hidden,
                 counts:        counts)
    else
      counts[:files] += 1
      size = File.size(full_path)
      puts "#{prefix}#{connector}#{entry}"
    end
  end
end

puts "#{root}"
counts = { files: 0, dirs: 0 }
print_tree(root, depth: options[:depth], show_hidden: options[:show_hidden], counts: counts)
puts "\n#{counts[:dirs]} directories, #{counts[:files]} files"

# ruby tree.rb ~/Projects/my-app --depth 2
# /Users/yosia/Projects/my-app
# ├── Gemfile
# ├── README.md
# ├── lib/
# │   └── my_app.rb
# └── spec/
#     └── my_app_spec.rb
#
# 2 directories, 4 files
```
