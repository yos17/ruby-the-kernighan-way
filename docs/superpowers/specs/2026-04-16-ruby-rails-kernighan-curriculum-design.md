# Ruby & Rails — The Kernighan Way (Curriculum Redesign)

**Date:** 2026-04-16
**Status:** Draft for user review
**Author:** Brainstormed with Claude
**Scope of this spec:** Curriculum architecture, 13-chapter syllabus, chapter anatomy template, repo layout, voice and style guide, salvage plan from the current book, build order. Detailed per-chapter prose / code / exercise text deferred to follow-up specs.

---

## Goal

Take the current `ruby-the-kernighan-way` book — a 13-chapter draft that ends at metaprogramming and assumes prior programming experience — and redesign it as a tighter, more demanding **Kernighan-style book** that takes a *computer-comfortable beginner* to **DHH-level Ruby and Rails skill**: able to build a mini-Rails framework and ship gems to RubyGems, fluent in Hotwire and the Rails 8 Solid stack, productive with modest abstractions.

## Reader profile

- Computer-comfortable but never programmed
- Has a Mac/Linux/Windows machine they can install Ruby on
- Willing to read demanding prose (this is a Kernighan-style book, not a hand-holding tutorial)
- Wants to *understand* Ruby, not just *use* Rails — explicitly stated goal: build mini-Rails and popular gems

## Skill bars (definition of done)

By the last page, the reader owns:

1. A `bin/` of small Unix-flavored Ruby CLI tools they wrote
2. One published gem on RubyGems with their name on it
3. A working **mini Rails framework** they hand-rolled from scratch
4. A real Rails app deployed to the open internet via Kamal

## Pedagogical principles (locked)

The following principles are non-negotiable. Any change requires re-opening this spec.

- **Tool-driven, not concept-driven.** Each chapter builds 2-3 substantive programs. Concepts emerge as the program needs them. Chapter titles describe what's built; they never name a language feature ("Strings, Numbers, Collections" is a *theme* of programs, not a feature survey).
- **Compositional.** Programs accumulate. Ch 10's `tiny-framework` directly composes Ch 6's metaprogramming. Ch 8's `tasks` capstone composes Ch 1-7. Ch 11/12 build on each other. Ch 13 deploys what Ch 11/12 built. The reader's `bin/` and `lib/` grow over time into a real personal toolkit they own.
- **Modern Ruby idioms woven throughout.** Pattern matching shows up in Ch 3's `case` discussion. `Data.define` shows up in Ch 5. `it` block param shows up in Ch 4. `&:method`, endless methods, rightward assignment, numbered block params used naturally. There is *no* "Modern Ruby" chapter.
- **Build mini-Rails before using real Rails.** Ch 10 is non-negotiable. After hand-rolling tiny-rack → tiny-router → tiny-orm → tiny-renderer → tiny-framework, opening real Rails for the first time isn't magic — it's "the polished version of what I built last week."
- **Tests, lint, CI: deferred.** Tests appear only at Ch 9 (gem authoring), in service of shipping a maintainable gem (Minitest, the simple ships-with-Ruby choice). Lint and CI are not added.
- **Kernighan-terse voice throughout, with one beginner concession in Ch 0-2.** Same dense prose page 1 to last page, except the first three chapters give each new keyword/method *one* explanatory sentence on first introduction. After Ch 3, assume reading muscle.
- **DHH-aligned stack.** Rails 8, Hotwire (Turbo + Stimulus), Solid Queue, Solid Cache, Rails 8 built-in auth, Kamal deploy. Server-rendered HTML throughout.
- **DHH-rejected approaches explicitly cut.** Service objects / hexagonal / clean architecture / SPAs / microservices / RBS-Sorbet / Devise / Sidekiq / Redis / heavy testing methodologies / deep concurrency primitives at the app level / profiling-as-its-own-discipline / multi-DB / Rails engines as a curriculum topic. Where one of these comes up naturally (e.g., a sidebar in Ch 12 noting that DHH would not extract a service object here), it's mentioned to argue against, not to teach.

## Curriculum: 13 chapters, ~385 pages

| # | Chapter | Programs you build | Pages |
|---|---|---|---|
| 0 | **Setup** | Install Ruby + VS Code; run your first file; read errors | 10 |
| 1 | **A Tutorial Introduction** | `hello.rb` · `calc.rb` · a tiny file processor — variables, conditionals, loops, methods, file I/O all introduced fast | 25 |
| 2 | **Strings, Numbers, Collections** | `histogram.rb` · `csv-stats.rb` · `wordfreq.rb` — strings, numbers, arrays, hashes, ranges, symbols | 25 |
| 3 | **Control Flow and Iteration** | `grep.rb` · `top-errors.rb` · log analyzer — `if` / `case` / `while` / `until` / `Enumerable`. Pattern matching introduced alongside `case`. | 25 |
| 4 | **Methods, Blocks, Procedures** | `pipeline.rb` · memoizer · event bus — methods, blocks, procs, lambdas, `yield`, `it` block param, endless methods | 25 |
| 5 | **Objects, Classes, Modules** | `addr.rb` · `shelter.rb` · plugin system — classes, modules, inheritance · object model + method lookup worked through here · `Data.define` for value objects | 30 |
| 6 | **Metaprogramming** | `mini-attr.rb` (`define_method`) · `flex.rb` (`method_missing`) · `mini-dsl.rb` (`class_eval` + hooks) | 35 |
| 7 | **Files, Errors, the Outside World** | `logwatch.rb` · JSON config loader · tiny HTTP client — File I/O · JSON · CSV · exceptions · `binding.irb` · ENV · `Net::HTTP` | 25 |
| 8 | **Halfway Capstone — a Real CLI Tool** | `tasks` — a complete personal task tracker composing everything from Ch 1-7 (persistence, errors, search, export). The "you can ship Ruby things now" milestone. | 25 |
| 9 | **Building a Gem** | Tour through a real gem's source · package `tasks` (or another tool of yours) as a gem · Minitest enters · publish to RubyGems | 25 |
| 10 | **A Tiny Web Framework** ⭐ | `tiny-rack` → `tiny-router` (uses Ch 6's `class_eval`) → `tiny-orm` (uses Ch 6's `method_missing`) → `tiny-renderer` → compose into **`tiny-framework`** — *the centerpiece* | 40 |
| 11 | **Real Rails: Models, Controllers, Views** | Hello Rails · Active Record (migrations, validations, associations, N+1, `includes`) · controllers · views (ERB, partials, helpers). Build a blog with comments. | 35 |
| 12 | **Real Rails: Hotwire, Forms, Auth, Jobs, Caching** | Hotwire (Turbo + Stimulus) · `form_with` + Active Storage · Rails 8 built-in auth · ActionMailer · Solid Queue · Solid Cache | 40 |
| 13 | **Shipping** | Kamal deploy · production basics · modest architecture (when DHH would extract a class vs not) · deploy your blog to a real host | 20 |

**Total: 13 chapters, ~385 pages.**

## Chapter anatomy (template)

Every chapter follows this structure:

```
1. Title and 2-4 sentence opening
   - Names the chapter's programs
   - States what will emerge
   - No "in this chapter we'll learn..." preamble

2. Body
   - Code first, explanation second, never the reverse
   - The chapter's 2-3 main programs are built in narrative order
   - Concepts emerge as the program needs them
   - Headings are terse: "Pattern matching" not "Understanding pattern matching"
   - Every runnable code block is followed by its expected output (`# =>` or fenced)

3. What you learned
   - Small recap table (concept | key point), 5-10 rows
   - No essay-style summary

4. Exercises
   - 4-8 substantive exercises
   - Each asks the reader to extend a chapter program OR write a sister program
   - Each has a starter file in `exercises/` and a solution in `exercises/solutions/`
   - "Substantive" = the exercise requires writing or significantly modifying a working program. No one-line trivia.
```

**Page budgets** are in the syllabus table. Centerpiece is Ch 10 (~40 pages); shortest is Ch 0 (~10 pages).

## Repo layout

```
ruby-the-kernighan-way/
├── README.md                        # book intro + chapter index + setup pointer
├── chapters/
│   ├── 00_setup/
│   │   └── README.md
│   ├── 01_tutorial/
│   │   ├── README.md                # the chapter prose
│   │   ├── examples/                # runnable example programs
│   │   │   ├── hello.rb
│   │   │   ├── calc.rb
│   │   │   └── tiny_processor.rb
│   │   └── exercises/
│   │       ├── 1_extend_calc.rb     # starter: spec in header comment, TODO markers
│   │       ├── 2_celsius_converter.rb
│   │       ├── ...
│   │       └── solutions/
│   │           ├── 1_extend_calc.rb
│   │           └── 2_celsius_converter.rb
│   ├── 02_strings_collections/
│   │   └── (same shape)
│   ├── 03_control_flow/
│   ├── 04_methods_blocks/
│   ├── 05_objects_classes/
│   ├── 06_metaprogramming/
│   ├── 07_files_errors_outside/
│   ├── 08_halfway_capstone/
│   │   ├── README.md
│   │   ├── starter/                 # `tasks` skeleton
│   │   └── reference_solution/      # complete reference build
│   ├── 09_building_a_gem/
│   │   ├── README.md
│   │   ├── tour/                    # walkthrough of an existing gem's source
│   │   └── your_gem/                # the gem you build (skeleton + reference)
│   ├── 10_tiny_framework/
│   │   ├── README.md
│   │   ├── examples/
│   │   │   ├── tiny_rack.rb
│   │   │   ├── tiny_router.rb
│   │   │   ├── tiny_orm.rb
│   │   │   ├── tiny_renderer.rb
│   │   │   └── tiny_framework/      # composed mini-Rails (a directory project)
│   │   └── exercises/
│   ├── 11_real_rails_1/
│   │   ├── README.md
│   │   ├── checkpoints/             # snapshots at named build points
│   │   └── exercises/
│   ├── 12_real_rails_2/
│   ├── 13_shipping/
├── archive/                         # the OLD 13-chapter book preserved unchanged
│   └── chapters/                    # frozen — no edits ever
└── Gemfile                          # appears once Ch 9 introduces Bundler/Minitest
```

The `archive/` directory preserves the current book unchanged so its content remains accessible while the rewrite happens. New chapters live under `chapters/`.

## Voice and style guide (locked)

- **Tone:** Kernighan-terse throughout. Direct prose. Sparing adverbs. No "let's", "we're going to", or "in this section we'll explore" preambles.
- **Beginner concession in Ch 0-2 only:** each new keyword or built-in method gets ONE explanatory sentence on first introduction (not a paragraph, not a callout box). After Ch 3, assume the reader has built reading muscle.
- **Code comments:** sparing. Comments only when behavior is non-obvious or there's a hidden constraint. Concept teaching happens in prose, not in `# this is a loop` comments.
- **Output examples:** every runnable code block is followed by its expected output, in a `# =>` comment or in a separate triple-backtick block. The reader can confirm what the program does without running it.
- **Opinions stated, not hedged:** *"Use `&:method` here. The expanded form is wrong here."* Not *"Some prefer `&:method`."* The book takes positions and defends them.
- **No emoji, no callout boxes, no "Pro tip" / "Congrats!" patterns.** K&R has none of that. The reader is treated as an adult.
- **Headings:** terse. *"Pattern matching"* not *"Understanding pattern matching: a comprehensive guide"*. Single-line section breaks, no decoration.
- **Cross-references:** by chapter and section number (*"see Ch 5 §3"*), not by hyperlink. The reader can find them.
- **Modern Ruby idioms used naturally everywhere:** pattern matching in Ch 3, `Data.define` in Ch 5, `it` block param in Ch 4, endless methods in Ch 4, `&:method` from Ch 4 onward. They appear at the moment they're useful — never as a "modern Ruby" sidebar or chapter.

## Salvage plan from the current book

Current `chapters/01_getting_started/` through `chapters/13_debugging/` move (verbatim, unedited) to `archive/chapters/`. Salvage means *mining the material* for new chapter content; the prose gets rewritten for the new audience and voice.

| Current chapter | New target | Notes |
|---|---|---|
| `01_getting_started` | Ch 1 (Tutorial Introduction) | Calculator example seeds new `calc.rb`; greeter survives as Ch 0/1 first program |
| `02_types_and_expressions` | Ch 2 (Strings, Numbers, Collections) | Converter example seeds Ch 2 |
| `03_control_flow` | Ch 3 | Direct material reuse; pattern matching added |
| `04_methods_and_blocks` | Ch 4 | Direct; modern syntax (endless methods, `it`) added |
| `05_objects_and_classes` | Ch 5 (Objects, Classes, Modules) | BankAccount → seeds Ch 5; Vector + Matrix exercises move to Ch 5 exercises; Comparable example stays |
| `06_modules_and_mixins` | Ch 5 | Folded into Ch 5 |
| `07_collections` | Ch 2 | Folded into Ch 2 |
| `08_io_and_files` | Ch 7 (Files, Errors, Outside World) | Direct |
| `09_error_handling` | Ch 7 | Folded |
| `10_metaprogramming` | Ch 6 (Metaprogramming) | **Biggest salvage** — current Ch 10 (~22k chars) mines into nearly all of new Ch 6 |
| `11_concurrency` | Mostly dropped | DHH-style: app devs almost never write this; Rails handles it. Preserved in `archive/`. |
| `12_gems_and_stdlib` | Ch 9 (gem half) + Ch 7 (stdlib half) | Standard library material salvages into Ch 7; gem material into Ch 9 |
| `13_debugging` | Ch 7 | `binding.irb` and debug gem material moves into Ch 7's errors discussion |

## Build order

Each phase below becomes its own follow-up spec:

| Phase | Spec name (suggested) | Chapters | Key deliverable |
|---|---|---|---|
| 1 | Repo restructure + voice exemplar | Move current → `archive/`, scaffold new dirs, write Ch 0 + Ch 1 | Two finished chapters that *set the voice template* for everything after. **User reviews voice quality before Phase 2 starts.** |
| 2 | Foundations | Ch 2, 3, 4 | The reader can write idiomatic Ruby data and control flow |
| 3 | OO + Metaprogramming | Ch 5, 6 | The Ruby skill core — object model + meta primitives |
| 4 | I/O + halfway capstone + gem authoring | Ch 7, 8, 9 | Reader publishes a real gem |
| 5 | Tiny framework | Ch 10 | The centerpiece. Gets its own focused spec. |
| 6 | Real Rails | Ch 11, 12 | Reader builds a real Rails app |
| 7 | Shipping + final pass | Ch 13 + copyedit | Book is complete; reader has shipped to production |

## Out of scope for this spec

- Detailed prose content per chapter
- Exact code listings per chapter
- Exact exercise text per chapter
- Test framework choices for chapters that need tests beyond Ch 9 (Minitest is locked for Ch 9; later choices deferred)
- Linting / CI / Rakefile decisions (deferred indefinitely — user does not want this)

Each phase listed in *Build order* gets its own follow-up spec when its time to implement.

## Locked decisions

The following decisions are locked. Any change requires re-opening this spec.

1. 13 chapters, Shape B (Kernighan-style with bootcamp scaffolding)
2. Audience: computer-comfortable, never-programmed beginner
3. Tool-driven structure: each chapter builds 2-3 substantive programs
4. Compositional: later chapters compose earlier ones (Ch 10 ← Ch 6; Ch 8 ← Ch 1-7; Ch 12 ← Ch 11; Ch 13 ← Ch 12)
5. Modern Ruby idioms woven throughout — no separate chapter
6. Voice: Kernighan-terse throughout; one-sentence-per-new-thing concession in Ch 0-2 only
7. Exercises: 4-8 substantive per chapter; starter files + solutions in `exercises/` and `exercises/solutions/`
8. Tests appear only from Ch 9 onward, in service of gem authoring (Minitest)
9. DHH stack in Ch 11-13: Rails 8, Hotwire, Solid Queue, Solid Cache, built-in auth, Kamal deploy
10. DHH-rejected concepts (service objects, hexagonal, types, microservices, Devise, Sidekiq, Redis, deep concurrency at app level, profiling as discipline) explicitly cut
11. Old book preserved verbatim in `archive/` — no deletion, no in-place edits
12. New `Gemfile` does not exist until Ch 9 introduces Bundler

## Open questions to revisit during implementation

These are deliberately deferred — they're real decisions but cheaper to make once Ch 0-1 are written and we have a concrete voice to test against:

- Exact chapter naming convention for directories: `01_tutorial/` vs `01_tutorial_introduction/` — short wins for now.
- Whether Ch 10's `tiny-framework` lives in `examples/tiny_framework/` (a directory) or `examples/tiny_framework.rb` (a single file) — depends on how big the composed framework gets.
- Whether the published gem in Ch 9 is the reader's own `tasks` from Ch 8, or a fresh smaller idea introduced in Ch 9 — depends on whether `tasks` is gem-shaped enough to justify packaging.
- Exact Ruby version target: lock to Ruby 3.4 (latest stable when we write); revisit at Ch 11 (Rails 8 has its own minimum).
