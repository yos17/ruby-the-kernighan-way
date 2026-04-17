# Exercise 2 — Read dotenv's source

`dotenv` is a small, popular gem (loads `.env` files into ENV). Read its source and compare with your Ch 7 dotenv exercise.

## Steps

```bash
gem install dotenv
gem which dotenv
# => path to lib/dotenv.rb
```

Read in this order:

1. `lib/dotenv.rb` (the entry point — what does it expose at the top level?)
2. `lib/dotenv/parser.rb` (the actual parsing — compare line-by-line with your Ch 7 solution)
3. `lib/dotenv/environment.rb`
4. The README on GitHub

## Things to look for and write down

- [ ] How is the parser organized? Is it one big method, or many small ones?
- [ ] What does the gem support that your version doesn't? (Variable interpolation? Multi-line strings? `export FOO=bar`?)
- [ ] How does it handle whitespace, quotes, escapes?
- [ ] How is the public interface (`Dotenv.load`, `Dotenv.parse`, etc.) different from a top-level function?
- [ ] Is there anything you'd do differently?

Reading other people's code is the fastest way to level up. Spend an hour here.
