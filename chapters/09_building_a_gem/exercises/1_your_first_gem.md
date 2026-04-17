# Exercise 1 — Gem one of your tools

Pick one of your earlier programs and ship it as a gem.

Suggested candidates:
- `wordfreq.rb` from Ch 2 → `wordfreq` gem
- `top_errors.rb` from Ch 3 → `top-errors` gem
- `safe.rb` from your Ch 5 exercises → `safe-runner` gem

## Checklist

- [ ] `bundle gem yourtool` (pick a name nobody on RubyGems is using)
- [ ] Move your code from the chapter into `lib/yourtool.rb` and `lib/yourtool/...rb`
- [ ] Wrap everything in `module Yourtool` — no top-level constants
- [ ] Edit `yourtool.gemspec` — replace TODO summary, description, homepage with real values
- [ ] Pick a license (MIT is fine) and update both gemspec and LICENSE.txt
- [ ] Set `spec.required_ruby_version = ">= 3.2"` in the gemspec
- [ ] Write at least three Minitest assertions in `test/`
- [ ] `bundle exec rake test` — they pass
- [ ] `git add -A && git commit -m "first commit"`  (gemspec uses `git ls-files`)
- [ ] `gem build yourtool.gemspec`
- [ ] `gem install ./yourtool-0.1.0.gem`
- [ ] In a fresh terminal: `ruby -r yourtool -e 'p Yourtool::VERSION'` works
- [ ] (Optional, real publish) `gem signin` once, then `gem push yourtool-0.1.0.gem`
- [ ] Visit `https://rubygems.org/gems/yourtool` and admire your work
