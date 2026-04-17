# Chapter 13 — Shipping

`localhost:3000` is not shipped. This chapter moves the blog onto a real server, under a real domain, with enough operational discipline that you can trust it.

The sequence is straightforward: fill in the deploy config, set secrets, run the first deploy, verify the app, then put boring routines around it: logs, backups, rollback, and one more feature shipped end to end.

## First deploy with Kamal

Rails 8 comes with Kamal configured by default. Kamal takes a fresh Linux machine, uploads your container, starts it, and switches traffic over once the new version is healthy.

You need:

- a Linux server with a public IP
- a domain name pointed at that server
- a container registry account
- SSH access to the box

Open `config/deploy.yml` and make it real:

```yaml
service: blog
image: your_user/blog

servers:
  web:
    - 1.2.3.4

proxy:
  ssl: true
  host: blog.example.com

registry:
  username: your_user
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
```

Put secrets in `.kamal/secrets`:

```bash
KAMAL_REGISTRY_PASSWORD=your-registry-token
RAILS_MASTER_KEY=your-master-key
```

Then do the first setup:

```bash
kamal setup
```

That prepares the server, installs what it needs, pulls the image, and configures the proxy.

Routine deploys are then one command:

```bash
kamal deploy
```

If you need to go back:

```bash
kamal rollback PREVIOUS_VERSION
```

The key idea is simple: deploys should be ordinary. If they feel like ceremonies, the process is too fragile.

## Production configuration

Check the defaults in `config/environments/production.rb` before DNS points at the box:

```ruby
config.cache_store = :solid_cache_store
config.active_job.queue_adapter = :solid_queue
config.action_cable.adapter = :solid_cable

config.force_ssl = true
config.log_level = :info
```

This is one of the nice Rails 8 changes: the default stack gives you cache, jobs, and cable without bringing in Redis just to make the app whole.

## SQLite in production

For a small app, SQLite is a reasonable production choice. The default Rails 8 shape keeps the primary, queue, and cache databases under `storage/`, so persistence matters more than sophistication.

A typical `database.yml` setup looks like:

```yaml
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  queue:
    <<: *default
    database: storage/production_queue.sqlite3
    migrations_paths: db/queue_migrate
  cache:
    <<: *default
    database: storage/production_cache.sqlite3
    migrations_paths: db/cache_migrate
```

Persist that directory with a volume in `config/deploy.yml`:

```yaml
volumes:
  - "blog_storage:/rails/storage"
```

If the app later outgrows SQLite, move to Postgres deliberately. Do it before concurrency becomes an emergency.

## Migrations and health checks

Deploying code is not enough. The schema has to move too.

Run migrations after deploy:

```bash
kamal app exec 'bin/rails db:migrate'
```

Or, when bringing up a fresh environment:

```bash
kamal app exec 'bin/rails db:prepare'
```

Then verify the app is actually alive:

- open the site in a browser
- hit `/up`
- load a page that talks to the database
- sign in and create one record

Do not treat "container booted" as the same thing as "application works."

## Logs, console, and inspection

When production misbehaves, start with the boring tools:

```bash
kamal app logs
kamal app logs --grep ERROR
kamal app exec --interactive 'bin/rails console -e production'
```

Use the console carefully. Reading is cheap. Writing is permanent.

Add request context to the logs so one user's path through the app is traceable:

```ruby
config.log_tags = [:request_id, ->(req) { req.session[:user_id] || "-" }]
```

And connect one error tracker. Sentry, Honeybadger, and Rollbar are all fine. The mistake is running with none.

## Backups

Backups are part of shipping, not a future improvement.

For SQLite, copying the database file is enough. For Postgres, use `pg_dump`. The important part is not the backup script. It is the restore drill.

```ruby
class BackupJob < ApplicationJob
  def perform
    backup_path = Rails.root.join("backups", "db-#{Time.current.strftime('%Y%m%d')}.sqlite3")
    FileUtils.cp(Rails.root.join("storage/production.sqlite3"), backup_path)
  end
end
```

Schedule it, then restore from one copy on purpose. A backup you have never restored is just optimism on disk.

## Keep the app boring

Shipping is the wrong time to introduce extra layers. If one controller action is ugly, fix that action. If two queries repeat, extract the query. If five things really share one behavior, extract a class or module. Do not add service objects, presenters, or new abstractions on deploy day just because production feels important.

The application already has enough moving parts: web, database, jobs, mail, cache, deploys. Keep the code as plain as the problem allows.

## Performance — the first things to check

Most performance problems in a small Rails app come from familiar places:

1. N+1 queries. Fix with `includes`.
2. Missing indexes. Add them with migrations.
3. Slow partial rendering. Cache the repeated pieces.
4. Jobs not being worked. Check that the worker process is running.
5. Huge pages and images. Resize and paginate before you optimize anything exotic.

If you need a profiler, add one in development and measure there first.

## Capstone: ship one more feature

Build one feature on the blog from scratch and deploy it. Good candidates:

- tags with a `/tags/:slug` page
- an RSS feed
- drafts and publish/unpublish
- a like button with Turbo Streams
- email subscriptions for comments

Pick one that forces you to touch models, routes, views, and deployment. That is the point of the exercise.

## Definition of shipped

The feature counts as shipped only when all of these are true:

- someone else can run the app locally from the README
- the feature has at least one automated happy-path test
- you have a working backup and have restored it once
- you have tried a rollback
- the live app serves the feature on your real domain

If one of those is missing, it may be deployed, but it is not shipped.

## Common pitfalls

- **Deploying code against the old schema.** Run the migration step every time it matters.
- **Secrets in tracked files.** `.kamal/secrets` is for secrets; git is not.
- **No restore rehearsal.** Disaster recovery is not the time to discover your backups are unusable.
- **Treating SQLite as infinite.** It is a good default, not a permanent vow.
- **Never testing rollback.** The first rollback should not happen during a real incident.

## Production debugging

When the live app fails, use the same loop every time:

1. read the logs and the first application frame in the stack trace
2. reproduce locally if you can
3. fix the code, not the symptom
4. deploy
5. verify the exact failing path

Tools worth knowing:

- `kamal app logs` for the live trace
- `kamal app exec --interactive 'bin/rails console -e production'` for inspection
- `/up` for fast health checks
- your error tracker for exceptions you did not personally witness
- request ids in logs so one request can be followed cleanly

## What you learned

| Concept | Key point |
|---|---|
| Kamal | deployment should become routine, not ceremonial |
| `kamal setup` / `kamal deploy` / `kamal rollback` | first deploy, normal deploy, undo |
| Persistent `storage/` volume | SQLite, queue, and cache data must survive container swaps |
| `db:migrate` / `db:prepare` | code and schema have to move together |
| `/up` and logs | verify the application, not just the container |
| Backups and restores | recovery matters more than backup scripts |
| Rollback drills | the path back should be rehearsed |
| Boring architecture | extra layers are not a reward for reaching production |

## What you've built

By the end of the book, you have:

- a collection of small Ruby command-line tools
- a gem published under your own account
- a tiny Rails-like framework you built by hand
- a real Rails app with auth, jobs, caching, and uploads
- that app running on a real server under a real domain

That is enough skill to keep going without training wheels.

## Where to go next

- Read real Rails applications end to end.
- Learn SQL more deeply.
- Read the Rails guides on caching, security, and production tuning carefully.
- Contribute one small fix to a gem or to Rails itself.
- Build something you would actually use for six months.
