# Chapter 13 — Shipping

The blog runs on `localhost:3000`. Now we put it on the internet under a real domain. This chapter walks through deployment with Kamal (the tool DHH wrote for shipping Rails apps to your own servers), production sanity, and modest architecture choices for when the app starts to grow. After this you'll have a real, public Rails app with your name on it.

## Kamal — deploy to your own servers

Rails 8 ships with Kamal in the Gemfile. It's a thin layer over Docker + SSH that pushes your container to a server, runs it, and gracefully cuts traffic over.

You need:

- A Linux server with a public IP (Hetzner, DigitalOcean, AWS Lightsail, or any cheap VPS — $5-10/mo is enough for a small blog)
- A domain name pointed at the server
- Docker Hub (or another container registry) account
- SSH access to the server

`config/deploy.yml` (Rails generated this — open it):

```yaml
service: blog
image: your_user/blog

servers:
  web:
    - 1.2.3.4    # your server's IP

proxy:
  ssl: true
  host: blog.example.com   # your domain

registry:
  username: your_user
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_PASSWORD
```

Set the secrets locally:

```bash
echo "your-docker-hub-token" > .kamal/secrets
# add KAMAL_REGISTRY_PASSWORD=... and others to .kamal/secrets (it's gitignored)
```

First-time setup on a fresh server:

```bash
kamal setup
```

This: SSHes to your server, installs Docker if missing, pulls your built image, starts the container, configures the proxy (kamal-proxy) for HTTPS, fetches Let's Encrypt certs.

Routine deploys after that:

```bash
git push       # to your repo
kamal deploy   # builds the image, pushes to registry, swaps the running container
```

Zero-downtime deploys come for free — Kamal starts the new container, health-checks it, switches the proxy, drains the old one.

Rollback if something's wrong:

```bash
kamal rollback PREVIOUS_VERSION
```

## Production environment

Edit `config/environments/production.rb` for your real settings. Defaults are sensible; key things to verify:

```ruby
config.cache_store = :solid_cache_store     # Solid Cache (Ch 12)
config.active_job.queue_adapter = :solid_queue   # Solid Queue (Ch 12)
config.action_cable.adapter = :solid_cable       # Solid Cable (Ch 12)

config.force_ssl = true       # redirect http → https
config.log_level = :info
```

The "Solid trifecta" (Solid Queue + Solid Cache + Solid Cable) means **no Redis required for a Rails 8 deploy.** Everything runs on your one Postgres or SQLite database. For a small blog, you can deploy on a single $5 VPS with SQLite and Solid stack.

## SQLite in production

Rails 8 supports SQLite in production (DHH made the case at Rails World 2024). It's fast enough for many real apps. To use it:

```yaml
# config/database.yml
production:
  adapter: sqlite3
  database: storage/production.sqlite3
```

Add a Kamal volume mount so the SQLite file persists across deploys:

```yaml
# config/deploy.yml
volumes:
  - "blog_storage:/rails/storage"
```

For when you outgrow SQLite, switch to Postgres in `database.yml`. The Solid stack works on either.

## Logs

After deploy:

```bash
kamal app logs           # tail logs across all servers
kamal app logs --grep ERROR
```

Logs go to stdout; Kamal captures them. For long-term retention, ship them to a log aggregator (Logtail, Datadog, Papertrail).

## Backups

For SQLite, periodic file copies. For Postgres, `pg_dump`. Schedule with `cron` or a Solid Queue job:

```ruby
class BackupJob < ApplicationJob
  def perform
    backup_path = Rails.root.join("backups", "db-#{Time.current.strftime('%Y%m%d')}.sqlite3")
    FileUtils.cp(Rails.root.join("storage/production.sqlite3"), backup_path)
    # then rsync to S3 / B2 / wherever
  end
end

# config/recurring.yml — Solid Queue's cron
production:
  daily_backup:
    class: BackupJob
    schedule: every day at 3am
```

## Environment variables

Production secrets go in `config/credentials.yml.enc` (encrypted, committed) plus `.kamal/secrets` (un-encrypted, gitignored, set on the server).

Edit credentials:

```bash
EDITOR=vim bin/rails credentials:edit
```

Access in code:

```ruby
Rails.application.credentials.api_key
```

## Modest architecture

DHH's writing on architecture has a clear thesis: **Rails defaults work for surprisingly large apps**. Don't reach for service objects, query objects, hexagonal architecture, or microservices until you've actually felt the pain that those patterns address.

That said, here are the patterns to know — when the time comes:

- **Concerns** (`app/models/concerns/foo.rb`, `app/controllers/concerns/bar.rb`) — modules included into models or controllers to share methods. Bundled with Rails. Use them when behavior crosses several models. Avoid them as a way to make a fat model "shorter" — extracting code into a concern doesn't reduce complexity, it relocates it.

- **Service objects** — a class with a single `call` method that orchestrates a multi-step operation (e.g., `RegisterUser.call(email: ...)`). DHH argues most "service objects" are hiding logic that belongs on the model. Use sparingly, name them after the verb (`ImportPost`, `RankSearchResults`), and keep them stateless.

- **Form objects** — a non-AR class that uses `ActiveModel::Model` for validations and form binding, when a form spans multiple models. Useful. Often simpler than Rails 7's `accepts_nested_attributes_for`.

- **Query objects** — extract complex AR queries into their own class. Useful when a single query becomes 30+ lines.

- **Decorators / presenters** — wrap a model in a class that adds view-only methods. Often a Rails helper does the same thing with less ceremony. Consider helpers first.

The DHH discipline: if there are *two* messy methods that look similar, leave them. If there are *five*, extract. Don't preemptively engineer.

## Performance — what to actually do

Profile when slow. Don't optimize speculatively. The usual suspects in a Rails app:

1. **N+1 queries** — fix with `includes`. Bullet flags them in development.
2. **Missing database indexes** — `bin/rails db:migrate` after `add_index :posts, :author_id`.
3. **Slow rendering** — fragment-cache (Ch 12).
4. **Job queues backing up** — measure with Solid Queue's dashboard.
5. **Memory leaks** — restart workers periodically; profile with `derailed_benchmarks`.

For deeper investigation:

```ruby
# Gemfile
group :development do
  gem "rack-mini-profiler"
  gem "memory_profiler"
end
```

`rack-mini-profiler` adds a small performance widget to every page in dev. Click it; see where the time went.

## Capstone: ship one feature on the blog

You've followed along through Ch 11-12. Now design and build *one new feature* on the blog from scratch, end to end, including a deploy.

Suggestions:

- **Tags**: posts can have many tags; add a `/tags/:slug` page showing all posts with that tag. Use a `has_many :through` association.
- **RSS feed**: add a `/feed.rss` route that returns valid RSS 2.0 XML.
- **Drafts**: a post stays unpublished until the author hits "Publish." `published_at IS NULL` filters drafts. Show drafts only to their author.
- **Like button**: a Stimulus + Turbo Streams interaction that increments a like count without a page reload.
- **Email subscriptions**: visitors can subscribe to a post's comments via email. ActionMailer + Solid Queue + an unsubscribe link.

Pick one. Build it. Deploy it. Tell someone.

## What you learned

| Concept | Key point |
|---|---|
| Kamal | deploy Docker containers to your own servers via SSH |
| `kamal setup` / `kamal deploy` / `kamal rollback` | first deploy / routine deploy / undo |
| Zero-downtime deploys | proxy switches once new container is healthy |
| Solid trifecta | Queue + Cache + Cable, no Redis required |
| SQLite in production | viable for many apps; persist with a Kamal volume |
| `kamal app logs` | tail production logs |
| `bin/rails credentials:edit` | encrypted credentials, committed to git |
| `.kamal/secrets` | per-server secrets, gitignored |
| Modest architecture | Rails defaults work large; concerns/services/forms only when warranted |
| Performance | profile, don't speculate; N+1 + indexes + caching first |

## What you've built

Working backwards from this chapter:

- Phase 0-1: A `bin/` of small Ruby tools you wrote (`greet.rb`, `wc.rb`, `grep.rb`, `addr.rb`, `tasks` CLI...)
- Ch 9: A real gem published to RubyGems
- Ch 10: A working **mini Rails framework** you hand-rolled
- Ch 11-12: A blog application with auth, Hotwire, jobs, caching
- Ch 13: That blog deployed to a real server, on a real domain, with HTTPS

The book covered:
- ~14 chapters
- ~75 substantial example programs
- ~70 exercises (not counting the Rails walkthroughs)
- Zero promises that any of it would feel easy

## Where to go next

A few directions worth your time, depending on what you want to build:

- **Read other people's Rails code.** Open the source of a gem you use. Better, find a small open-source Rails app on GitHub and read it end to end. The Discourse forum and the Mastodon server are big; Github's own (closed) Rails monolith is too. For something readable, look at https://github.com/heartcombo/devise (auth gem) or any of basecamp's open-source like https://github.com/basecamp/kredis.

- **Read about Ruby internals.** *Ruby Under a Microscope* by Pat Shaughnessy walks through how Ruby actually executes your code. After Ch 6 + Ch 10, you'll get more out of it than you think.

- **Build something you'd use.** A reading-list tracker. A shopping list shared with one other person. A workout log. An RSS reader. Anything where you're the user.

- **Contribute to Rails or a gem.** Even a typo fix. The Rails contributors page lists thousands of names; one of them was once at exactly this point.

- **Learn a related craft.** SQL deeper. CSS deeper. The Unix shell deeper. Each of these is worth its own book; each multiplies what you can do with Ruby.

You can write Ruby. You can build Rails apps. You can ship them. That's the bar this book set out to mark, and you're at it.
