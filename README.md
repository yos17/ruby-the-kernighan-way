# Ruby & Rails — The Kernighan Way

This book teaches Ruby the way K&R teaches C: by building small tools that do real work. You start with `hello.rb` and a calculator. You end with a tiny Rails-like framework, a published gem, and a deployed Rails app.

It is written for a reader who is comfortable using a computer and new to programming. It is not a reference manual and it is not a Rails cookbook. It is a guided sequence of programs. If a chapter feels heavy, stay with the program first and come back for the supporting details on a second pass. If you already write Ruby comfortably, the preserved draft in [`archive/`](./archive/) is likely the better reference.

## Why This Shape

Brian Kernighan's books teach by building. You learn C in *K&R* by writing tools — `wc`, `grep`, a calculator, a text formatter. You learn Unix in *The UNIX Programming Environment* by writing shell pipelines and a calculator language. The programs accumulate; later programs use earlier ones.

This book follows the same shape. Every chapter builds two or three working programs. The table of contents should feel like a list of files in `bin/`, not a list of language features.

## What you'll build

| Chapter | What you build |
|---|---|
| 0 | Setup: install Ruby, run your first file |
| 1 | A greeter, a calculator, a tiny line counter |
| 2 | A histogram, a CSV summarizer, a word-frequency counter |
| 3 | A `grep` clone, a top-errors log analyzer |
| 4 | A pipeline composer, a memoizer, a tiny event bus |
| 5 | An address book, an animal shelter, a plugin loader |
| 6 | Your own `attr_accessor`, a flexible-hash, a tiny DSL |
| 7 | A log watcher, a JSON config loader, a tiny HTTP client |
| 8 | **Halfway capstone**: a complete personal task tracker CLI |
| 9 | Build and publish a gem to RubyGems |
| 10 | **A tiny web framework** — Rack, router, ORM, renderer, composed |
| 11 | A real Rails app: blog with comments (Active Record, controllers, views) |
| 12 | The same blog with Hotwire, forms, auth, jobs, caching |
| 13 | Deploy your blog to a real host with Kamal |

## How to read

Keep a terminal open while you read. Type the programs yourself. Run them after every small change.

When a chapter feels dense, use this order:

1. ask what tool the chapter is building
2. identify the input and the output
3. trace one tiny example by hand
4. only then focus on the Ruby feature itself

Beginners usually do better when they keep the concrete program in view and let the abstraction catch up a little later.

Beginners often get lost when they try to understand every abstraction immediately. You do not need to understand every line on the first pass. You need to understand what problem the code is solving.

## Setup

```bash
ruby --version    # Ruby 3.4 or newer
```

If you don't have Ruby, start with [Chapter 0](./chapters/00_setup/).

## Book Layout

Read sequentially. Each chapter assumes the previous ones. Try the exercises before looking at the solutions.

The book uses `chapters/<NN>_<name>/` for each chapter:

```
chapters/01_tutorial/
├── README.md          # the chapter prose
├── examples/          # the programs the chapter builds
└── exercises/
    ├── 1_*.rb         # exercise starter files
    └── solutions/     # solutions, kept separate so you actually try
```

## Four ideas to keep returning to

The best programs are small, clear, and do exactly what they say. That's true in C, in shell, and in Ruby. When a chapter feels hard, come back to these four ideas:

- strings are not numbers until you convert them
- files are often just sources of strings and lines
- arrays and hashes are how Ruby helps you organize data
- methods, classes, and modules are ways to give structure to bigger programs

A lot of Ruby becomes easier when you reduce it to *data going in, data changing shape, and results coming out*.

## Status

All 14 chapters are drafted. The original 13-chapter book is preserved in [`archive/`](./archive/) for reference. Chapters 11-13 are guided walkthroughs rather than committed apps; everything before them is verified runnable Ruby.

- **Ch 0 — Setup** ✅
- **Ch 1 — A Tutorial Introduction** ✅
- **Ch 2 — Strings, Numbers, Collections** ✅
- **Ch 3 — Control Flow and Iteration** ✅
- **Ch 4 — Methods, Blocks, Procedures** ✅
- **Ch 5 — Objects, Classes, Modules** ✅
- **Ch 6 — Metaprogramming** ✅
- **Ch 7 — Files, Errors, the Outside World** ✅
- **Ch 8 — Halfway Capstone: a Real CLI Tool** ✅
- **Ch 9 — Building a Gem** ✅
- **Ch 10 — A Tiny Web Framework** ✅
- **Ch 11 — Real Rails: Models, Controllers, Views** ✅
- **Ch 12 — Real Rails: Hotwire, Forms, Auth, Jobs, Caching** ✅
- **Ch 13 — Shipping** ✅

Design spec: [`docs/superpowers/specs/2026-04-16-ruby-rails-kernighan-curriculum-design.md`](./docs/superpowers/specs/2026-04-16-ruby-rails-kernighan-curriculum-design.md).

## License

TBD
