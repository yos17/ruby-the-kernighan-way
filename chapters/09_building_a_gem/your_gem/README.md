# wordtools — example gem skeleton

This is the reference skeleton for the `wordtools` gem built in Chapter 9. It is NOT a published gem — it's a local example so you can see the layout.

To turn this into a published gem, copy the files into a fresh `bundle gem wordtools` skeleton and follow Chapter 9.

## Structure

```
your_gem/
├── lib/
│   ├── wordtools.rb           # entry point (require_relative the others)
│   └── wordtools/
│       ├── version.rb         # VERSION = "0.1.0"
│       ├── tally.rb           # Wordtools.tally(text)
│       └── top.rb             # Wordtools.top(text, n)
├── test/
│   └── test_wordtools.rb      # Minitest assertions
└── README.md
```

## Try it without packaging

From the chapter directory:

```bash
ruby -I your_gem/lib -e 'require "wordtools"; p Wordtools.top("the the and a", 2)'
# => [["the", 2], ["a", 1]]
```

## Run the tests

```bash
ruby -I your_gem/lib -I your_gem/test your_gem/test/test_wordtools.rb
```

You should see three passing assertions.
