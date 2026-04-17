# Ruby & Rails — The Kernighan Way

A tutorial book that takes a beginner from "I just installed Ruby" to "I can build a tiny Rails framework, ship a gem, and deploy a real Rails app." Designed for the reader who wants to *understand* Ruby — not just use Rails.

The book is for someone comfortable using a computer who has not programmed before. It is not for someone who already writes Ruby comfortably; for that, the existing 13-chapter draft preserved in [`archive/`](./archive/) is more useful.

## Why "Kernighan Way"

Brian Kernighan's books teach by building. You learn C in *K&R* by writing tools — `wc`, `grep`, a calculator, a text formatter. You learn Unix in *The UNIX Programming Environment* by writing shell pipelines and a calculator language. The programs accumulate; later programs use earlier ones.

This book follows the same shape. Every chapter builds 2-3 working programs. The TOC reads like a list of files in `bin/`, not a list of language features.

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

A good way to read this book is:

1. first, ask what tool or program the chapter is building
2. then identify the input and output
3. then trace one tiny example by hand
4. only after that, focus on the Ruby feature itself

That order matters.

Beginners often get lost when they try to understand every abstraction immediately. You do not need to understand every line on the first pass. You need to understand what problem the code is solving.

## Setup

```bash
ruby --version    # Ruby 3.4 or newer
```

If you don't have Ruby, start with [Chapter 0](./chapters/00_setup/).

## How to read

Read sequentially. Each chapter assumes the previous ones. Type the example programs yourself — don't just read them. Try the exercises before looking at the solutions.

The book uses `chapters/<NN>_<name>/` for each chapter:

```
chapters/01_tutorial/
├── README.md          # the chapter prose
├── examples/          # the programs the chapter builds
└── exercises/
    ├── 1_*.rb         # exercise starter files
    └── solutions/     # solutions, kept separate so you actually try
```

## Four ideas to keep coming back to

The best programs are small, clear, and do exactly what they say. That's true in C, in shell, and in Ruby. When a chapter feels hard, come back to these four ideas:

- strings are not numbers until you convert them
- files are often just sources of strings and lines
- arrays and hashes are how Ruby helps you organize data
- methods, classes, and modules are ways to give structure to bigger programs

A lot of Ruby becomes easier when you reduce it to *data going in, data changing shape, and results coming out*.

## Status

All 14 chapters written. The original 13-chapter draft is preserved in [`archive/`](./archive/) for reference. Chapters 11-13 are guided walkthroughs (you run `rails new`, generators, etc.) rather than committed apps; everything before is verified runnable Ruby.

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

(to be decided)
