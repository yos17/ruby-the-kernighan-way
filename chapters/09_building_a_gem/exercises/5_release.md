# Exercise 5 — Release v0.2.0

Practice the release flow.

## Steps

- [ ] Implement one new feature (any small thing — a new method, a new option)
- [ ] Add tests for it (a least one assert per behavior)
- [ ] `bundle exec rake test` — green
- [ ] Bump `VERSION` in `lib/yourtool/version.rb` from `"0.1.0"` to `"0.2.0"`
- [ ] Update `CHANGELOG.md`:
  ```markdown
  ## [0.2.0] - 2026-04-17
  ### Added
  - Brief description of the new feature.
  ```
- [ ] `git commit -am "Release 0.2.0"`
- [ ] `git tag v0.2.0`
- [ ] `gem build yourtool.gemspec`
- [ ] `gem push yourtool-0.2.0.gem`
- [ ] `git push --tags`

A clean release is its own art. Once you've done it three times, you stop thinking about it.

## Bonus: use `bundle exec rake release`

Bundler's generated Rakefile already gives you `rake release`, which does build + tag + push in one step. Read the Rakefile to see what it actually does. Run it on your next release.
