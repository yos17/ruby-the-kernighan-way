# Ruby: The Kernighan Way
### A comprehensive Ruby course — from zero to metaprogramming

Kernighan's books teach by doing. You learn C by writing a C compiler. You learn Unix by building Unix tools. This course teaches Ruby the same way: every concept introduced through a real program you build and run.

No slides. No multiple-choice questions. Just code, explanation, and things you build.

---

## Who This Is For

- You know at least one programming language (any language)
- You want to understand Ruby deeply, not just copy-paste it
- You want to reach metaprogramming — the part that makes Ruby special

## What You'll Build Along the Way

| Chapter | You Build |
|---------|-----------|
| 1 | A working calculator (CLI) |
| 2 | A unit converter |
| 3 | A number guessing game |
| 4 | A text statistics tool |
| 5 | A bank account class |
| 6 | A plugin system with modules |
| 7 | A CSV analyzer |
| 8 | A log file processor |
| 9 | A robust file parser with error handling |
| 10 | An attribute system (like Rails) |
| 11 | A concurrent web scraper |
| 12 | A CLI tool using gems |
| 13 | A buggy todo app (debug it!) |

## Structure

Each chapter has:
- **Concept explanation** — what it is and why it works the way it does
- **Working code** — programs you can run right now
- **Exercises** — things to build yourself
- **What you learned** — the key takeaways

A good way to read this book is:

1. first, ask what tool or program the chapter is building
2. then identify the input and output
3. then trace one tiny example by hand
4. only after that, focus on the Ruby feature itself

That order matters.

Beginners often get lost when they try to understand every abstraction immediately. You do not need to understand every line on the first pass. You need to understand what problem the code is solving.

## Setup

```bash
ruby --version    # need 3.x
gem --version     # comes with Ruby
```

That's all you need.

---

## The Philosophy

Ruby was designed to make programmers happy. It achieves this by making the language adapt to you — not the other way around. By the end of this course, you'll understand how Ruby does that, and you'll know how to use it yourself.

The best programs are small, clear, and do exactly what they say. That's true in C, in shell, and in Ruby.

One beginner reminder is worth keeping in mind through the whole book:

- strings are not numbers until you convert them
- files are often just sources of strings and lines
- arrays and hashes are how Ruby helps you organize data
- methods, classes, and modules are ways to give structure to bigger programs

If a chapter feels hard, come back to those four ideas. A lot of Ruby becomes easier when you reduce it to data going in, data changing shape, and results coming out.
