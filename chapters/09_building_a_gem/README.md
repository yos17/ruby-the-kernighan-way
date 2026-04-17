# Chapter 9 — Building a Gem

A *gem* is a packaged Ruby library. By the end of this chapter you will have published one to RubyGems with your name on it. We start by reading the source of a real gem to see how mature Ruby libraries are organized, then build and publish one of our own.

## What's in a gem

Every gem has, at minimum:

- A `.gemspec` file describing the gem (name, version, author, files)
- A `lib/` directory with the Ruby source
- A `README.md` so people know what it does

Most gems also have:

- `bin/` or `exe/` for executables
- `test/` or `spec/` with tests
- `Gemfile` for development dependencies
- `Rakefile` for `rake test`, `rake release`, etc.
- A `LICENSE` file
- A `CHANGELOG.md`

## Tour of a real gem

We're going to walk through `tty-prompt` — a small, well-maintained gem for interactive CLI prompts. It's the right size to read end-to-end (under 5,000 lines).

To follow along, install it and find its source:

```bash
gem install tty-prompt
gem which tty-prompt
# => ~/.gem/ruby/3.4.x/gems/tty-prompt-0.23.x/lib/tty/prompt.rb
```

Or browse on GitHub: `https://github.com/piotrmurach/tty-prompt`.

What to look at, in order:

1. **`tty-prompt.gemspec`** — declares the gem. Look at `spec.summary`, `spec.files`, `spec.required_ruby_version`. Notice that files are listed via `git ls-files` rather than `Dir`-globbing — only files tracked by git become part of the published gem.

2. **`lib/tty-prompt.rb`** — the entry point. One line: `require_relative "tty/prompt"`. The gem name is `tty-prompt` (with a hyphen) but its main module is `TTY::Prompt`. The entry file just bridges them.

3. **`lib/tty/prompt.rb`** — the public class. Read the `def initialize` to see what options it takes. Read a few of the public methods (`ask`, `select`, `multi_select`).

4. **`lib/tty/prompt/version.rb`** — `module TTY; module Prompt; VERSION = "0.23.x"; end end`. Just the version constant. Pulled into the gemspec.

5. **`lib/tty/prompt/`** subdirectory — each public method has its own file (`question.rb`, `list.rb`, `confirm.rb`). The `Prompt` class delegates to these. **Notice the size of each file — none over a few hundred lines.** This is the discipline good gems share: small files, one responsibility each.

6. **`spec/`** — the test suite. Open one or two spec files. See the `describe`/`it` structure (RSpec — Ch 12 covers it briefly).

The takeaway: a real gem is many small files, glued by a thin public API. Your own gem will follow the same shape.

## Building your gem

The framework `bundler` ships with Ruby and gives us a generator. Let's build a gem called `wordtools` (the chapter's exercise gem — yours can be anything).

```bash
cd ~
bundle gem wordtools
# (asks a few questions about test framework, license, code of conduct — pick any)
cd wordtools
```

Bundler created:

```
wordtools/
├── bin/                    # console + setup scripts for development
├── lib/
│   ├── wordtools.rb        # entry point
│   └── wordtools/
│       └── version.rb      # VERSION = "0.1.0"
├── test/                   # if you picked Minitest
├── wordtools.gemspec       # the gem manifest
├── Gemfile
├── Rakefile
├── README.md
└── LICENSE.txt
```

Open `wordtools.gemspec`. Edit the description, summary, and homepage to be real values. The generated gemspec uses `git ls-files` for the file list — meaning **you must commit your changes** before you can build the gem.

## The lib/ structure

Open `lib/wordtools.rb`. Bundler put a stub:

```ruby
require_relative "wordtools/version"

module Wordtools
  class Error < StandardError; end
end
```

This is the entry point. Replace the stub with something that actually does work. Suppose your gem provides `Wordtools.tally(text)` and `Wordtools.top(text, n)`:

```ruby
# lib/wordtools.rb
require_relative "wordtools/version"
require_relative "wordtools/tally"
require_relative "wordtools/top"

module Wordtools
  class Error < StandardError; end
end
```

```ruby
# lib/wordtools/tally.rb
module Wordtools
  def self.tally(text)
    text.downcase.scan(/[a-z]+/).tally
  end
end
```

```ruby
# lib/wordtools/top.rb
module Wordtools
  def self.top(text, n = 10)
    tally(text).sort_by { |w, c| [-c, w] }.first(n)
  end
end
```

A user installs your gem and writes:

```ruby
require "wordtools"
Wordtools.top("the quick brown fox jumps over the lazy dog the cat", 3)
# => [["the", 3], ["brown", 1], ["cat", 1]]
```

That's the full surface area: one `require`, a small set of well-named methods.

## Tests

Bundler's generator created a `test/` directory with one stub. Edit `test/test_wordtools.rb` (or whatever it generated):

```ruby
require "minitest/autorun"
require "wordtools"

class TestWordtools < Minitest::Test
  def test_tally_counts_lowercase_words
    result = Wordtools.tally("Hello hello WORLD")
    assert_equal({ "hello" => 2, "world" => 1 }, result)
  end

  def test_top_returns_n_most_frequent_alphabetically_for_ties
    result = Wordtools.top("the the and a", 2)
    assert_equal [["the", 2], ["a", 1]], result
  end

  def test_top_default_n_is_10
    text  = (1..15).map(&:to_s).join(" ").gsub(/\d+/) { |n| "word#{n}" }
    assert_equal 10, Wordtools.top(text).length
  end
end
```

Run them:

```bash
bundle exec rake test
```

A passing test suite is a precondition for shipping. **Don't release a gem without tests.** Even three trivial assertions are infinitely better than zero — they confirm `require "wordtools"` works without crashing, which is more than you'd think.

## Versioning

`lib/wordtools/version.rb` holds your version number. Use semantic versioning:

- **MAJOR.MINOR.PATCH** — like `1.4.2`
- Bump PATCH for backward-compatible bug fixes
- Bump MINOR for backward-compatible new features
- Bump MAJOR for breaking changes
- Pre-1.0 is the wild west — you can do what you want, but you signal "use at your own risk"

For the first release, use `0.1.0`.

## Building and installing locally

```bash
gem build wordtools.gemspec
# => Successfully built RubyGem
# => Name: wordtools
# => Version: 0.1.0
# => File: wordtools-0.1.0.gem
```

You now have a `.gem` file. Install it locally:

```bash
gem install ./wordtools-0.1.0.gem
```

Verify:

```bash
ruby -r wordtools -e 'p Wordtools.tally("hello hello world")'
# => {"hello"=>2, "world"=>1}
```

Your gem is locally installable.

## Publishing to RubyGems

You need a free RubyGems account. Sign up at `https://rubygems.org`, then run:

```bash
gem signin
# Email and password prompt
```

Push:

```bash
gem push wordtools-0.1.0.gem
# => Successfully registered gem: wordtools (0.1.0)
```

Done. Anyone in the world can now `gem install wordtools`. Your gem has a permanent page at `https://rubygems.org/gems/wordtools`.

## What changes for v0.1.1

- Edit code, fix a bug or add a feature
- Bump `VERSION` in `lib/wordtools/version.rb` to `"0.1.1"`
- Update `CHANGELOG.md` (start one if you haven't)
- Commit
- `gem build` → `gem push`

`bundler` ships with `rake release` which automates the build + tag + push. Read the Rakefile your generator wrote.

## A few production manners

Things that distinguish a "throwaway script" from a "useful gem":

- **Pin a `required_ruby_version`** in your gemspec — `spec.required_ruby_version = ">= 3.2"`. Don't make Ruby-2 users fail mysteriously.
- **List all dependencies** in the gemspec via `add_dependency` (runtime) or `add_development_dependency` (test/dev only). Don't `require` something you didn't declare.
- **Keep `lib/` self-contained.** Don't `require` files outside `lib/`. Use `require_relative` between your own files.
- **Don't pollute the top-level namespace.** Put everything inside `module Wordtools`. Never define `class String` at the top level of your gem.
- **README.md, README.md, README.md.** The very first thing every user reads. Show installation, one usage example, and link to docs.
- **License.** MIT is the safe default — it lets people use your code commercially. If you don't pick one, it's *all rights reserved* by default, which makes your gem unusable to many.

## Reading the source of a real gem (mini-tour)

If `tty-prompt` was too much, try one of these — all small enough to read in an afternoon:

- **`json` (the standard library implementation)** — `gem which json`. ~300 LOC of Ruby + a C extension; the Ruby side is the parser DSL.
- **`base64`** — ~50 LOC. Encodes/decodes Base64. Read it for fun; you'll understand what every line does.
- **`pathname`** — wraps `String` paths in an object with methods. ~600 LOC. A great example of "thin object wrapper around an idiom."
- **`dotenv`** — loads `.env` files into ENV. ~500 LOC. Compare with your Ch 7 exercise.

After you've read one, you'll never feel like gem source is mysterious again.

## Naming and discoverability

The name on your gemspec is the name people will type into `gem install` for years. Pick it like you mean it.

Conventions worth following:

- **CLIs get verb-style names.** `bundle`, `rails`, `kamal`, `thor`. The user types it as a command; it should read like one.
- **Libraries get noun-style names.** `nokogiri`, `pathname`, `sequel`. The user types `require "name"`; nouns scan better in source.
- **Brand-able vs descriptive.** `nokogiri` is brand-able (memorable, ungoogled before its release). `csv-stats` is descriptive (boring but obvious). Brand-able wins for gems you hope outlive their first version; descriptive wins for one-off internal tools.
- **Check RubyGems before you build.** `gem search -r ^wordtools$`. If it's taken, pick something else — RubyGems names are first-come, forever. The web UI at `https://rubygems.org/gems/wordtools` returns 404 if free.
- **Hyphens vs underscores.** The gem name uses hyphens for namespacing; the require path follows the directory layout under `lib/`. Gem `tty-prompt` lives at `lib/tty/prompt.rb` and you `require "tty-prompt"` (which then loads `tty/prompt`). Gem `wordtools` (no hyphen) lives at `lib/wordtools.rb` and you `require "wordtools"`. Pick one shape and stay consistent — a gem named `word-tools` that requires as `wordtools` confuses everyone.

## Common pitfalls

- **Forgetting to `git commit` before `gem build`.** The generated gemspec uses `git ls-files` for `spec.files`. Uncommitted (or untracked) files are *not* in the build. You'll publish a gem missing half its source and not realize until a user files an issue. Run `git status` before every `gem build`. If `git ls-files | grep lib/` doesn't list every file you expect, stop and commit.
- **Not pinning `required_ruby_version`.** Without it, your gem installs on Ruby 2.6 and explodes the first time it hits `Data.define` or pattern matching. Set `spec.required_ruby_version = ">= 3.2"` (or whatever your minimum truly is) and Bundler refuses the install with a clear message instead.
- **Releasing without a CHANGELOG.** Users of your gem need to know what changed between `0.1.4` and `0.2.0` before they bump. "Read the diff" is not an answer. Maintain `CHANGELOG.md` from `0.1.0` — even one line per release. The format at `https://keepachangelog.com` is the convention.
- **Gem name collisions.** `gem push` against a name someone else already owns fails with `Repushing of gem versions is not allowed.` But worse: a name *close to* a popular gem (`actverecord`, `nokogir1`) is a typosquatting trap and RubyGems may yank it. Search before you build, and don't be cute with misspellings.

## What you learned

| Concept | Key point |
|---|---|
| Gem layout | `lib/`, gemspec, `bin/`, `test/` — small files, thin public API |
| `bundle gem NAME` | scaffolds a complete gem skeleton |
| The gemspec | `name`, `version`, `summary`, `files`, `required_ruby_version`, dependencies |
| Versioning | semver: MAJOR.MINOR.PATCH; pre-1.0 is the wild west |
| `gem build` / `gem install` / `gem push` | build, test locally, publish |
| `bundle exec rake test` | run your tests |
| Minitest basics | `class FooTest < Minitest::Test`, `def test_x`, `assert_equal` |
| RubyGems publishing | `gem signin` once, then `gem push` per release |
| License (MIT) | non-trivial — without one, your gem is unusable to many |

## Going deeper

- Read `bundler`'s source. `gem which bundler`, then start at `lib/bundler.rb` and `lib/bundler/cli.rb`. It is the gem that ships with Ruby and runs every other gem you'll ever use. Skim the `Bundler::Definition` and `Bundler::Resolver` files — you don't need to follow every branch, just see how a serious gem is laid out.
- Pick a popular gem and read its CHANGELOG end to end: `rails`, `sidekiq`, `puma`, or `pundit`. Notice how they describe breaking changes, deprecation cycles, and the gap between `1.x` and `2.0`. Your own CHANGELOG will be better for it.
- Contribute to RubyGems itself. The `rubygems/rubygems` repo on GitHub has issues tagged `good first issue`. The codebase is the same Ruby idioms you're now reading fluently. A merged PR there is the credential you want.

## Exercises

1. **Pick a tool you wrote in Ch 1-7 and gem it.** Suggested candidates: `wordfreq` from Ch 2, `top_errors` from Ch 3, `safe.rb` from your Ch 5 exercises. Walk through `bundle gem yourtool`, move the code into `lib/`, add three Minitest assertions, build, install locally, then push to RubyGems if you're brave. Starter: `exercises/1_your_first_gem.md` (a checklist).

2. **Read `dotenv`'s source.** `gem install dotenv && gem which dotenv`. Read the parser. Compare with your Ch 7 dotenv exercise. Note three things their code does that yours didn't. Starter: `exercises/2_read_dotenv.md`.

3. **Add a CLI to your gem.** Add `bin/wordtools` (or whatever your gem is) so users can run it from the command line. Wire it through your gemspec's `executables`. Starter: `exercises/3_add_cli.md`.

4. **Write a Rakefile task.** Add `rake stats` to your gem that prints lines of code, number of public methods, number of tests. Starter: `exercises/4_rake_task.md`.

5. **Bump your gem to 0.2.0.** Add one new feature, write tests for it, update CHANGELOG, bump VERSION, build, push. Starter: `exercises/5_release.md`.

6. **Pick a small unmaintained gem and propose a fix.** Browse `https://rubygems.org/stats`. Find something with last update > 1 year. Read the code, find an issue (or check their issues), submit a PR. Starter: `exercises/6_oss_contribution.md`.
