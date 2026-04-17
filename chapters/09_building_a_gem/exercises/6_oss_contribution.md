# Exercise 6 — Make your first open-source contribution

Find a small Ruby gem in need of help and contribute.

## How to find one

- Browse `https://rubygems.org` — look for gems with last update > 1 year, low download counts, but a problem you can fix.
- Look at `awesome-ruby` (https://github.com/markets/awesome-ruby) — many small focused gems.
- Pick a gem you actually use — check its issues, see if there's a "good first issue."

## What counts as a contribution

- Fixing a typo in the README — counts.
- Adding a missing test for an edge case — counts.
- Updating dependencies — counts.
- Adding type signatures (RBS) — counts.
- Fixing a real bug — counts more.

## The flow

1. Fork the repo on GitHub
2. Clone your fork
3. Make a branch (`git checkout -b fix-typo`)
4. Make the change
5. Run the tests (often `bundle exec rake test`)
6. Commit, push, open a PR
7. Wait for the maintainer to respond. Some take days, some take weeks.

The first contribution is the hardest. After it lands, the rest are easy.
