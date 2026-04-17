# Exercise 4 — A custom Rake task

Add `rake stats` that prints code metrics for your gem.

## Goal

```bash
$ bundle exec rake stats
lines of code:    347
public methods:   12
test files:       3
test methods:     14
```

## Steps

Edit your `Rakefile`. Add:

```ruby
task :stats do
  loc = Dir["lib/**/*.rb"].sum { |f| File.readlines(f).count }
  methods = Dir["lib/**/*.rb"].sum { |f| File.read(f).scan(/^\s+def\s+/).count }
  test_files = Dir["test/**/*.rb"].count
  test_methods = Dir["test/**/*.rb"].sum { |f| File.read(f).scan(/^\s*def\s+test_/).count }

  puts "lines of code:    #{loc}"
  puts "public methods:   #{methods}"   # actually counts all `def`; refine if you want
  puts "test files:       #{test_files}"
  puts "test methods:     #{test_methods}"
end
```

(This is a quick-and-dirty count; for production you'd use the `flog` or `rubocop` gems.)

Run: `bundle exec rake stats`.
