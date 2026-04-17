# Chapter 12 — Real Rails: Hotwire, Forms, Auth, Jobs, Caching

You have a working blog from Ch 11. This chapter adds the Rails 8 / DHH-style stack: Hotwire (for live, JavaScript-free interactivity), proper forms with Active Storage uploads, built-in authentication, ActionMailer, Solid Queue (background jobs), and Solid Cache. By the end the blog will *feel* like a real production app.

## Hotwire — Turbo + Stimulus

Hotwire is two libraries that ship with Rails 8:

- **Turbo** — intercepts every link click and form submission, fetches the response over the wire, swaps the changed parts into the DOM. No page reloads. Zero JS code from you.
- **Stimulus** — a tiny JavaScript framework for sprinkling behavior on top of HTML. You write small controllers; Stimulus wires them up by data attributes.

The DHH thesis: *most apps don't need a SPA*. With Turbo handling navigation and partial updates, and Stimulus for the small bits of client-side behavior, you can build modern-feeling apps in pure Rails.

### Turbo Drive

Out of the box, every link and form submission in your blog is intercepted by Turbo Drive. The response is rendered, the body is swapped, the URL is updated — without a full page reload. Try it: navigate around your blog. Notice the page never flashes white. That's Turbo Drive.

To opt out for a specific link: `<%= link_to "Logout", logout_path, data: { turbo: false } %>`.

### Turbo Frames

A Turbo Frame is a section of the page that updates independently. Wrap any region in `<turbo-frame>`:

```erb
<turbo-frame id="post_<%= post.id %>">
  <%= post.title %>
  <%= link_to "Edit", edit_post_path(post) %>
</turbo-frame>
```

When the user clicks Edit, Turbo fetches `/posts/123/edit`, finds the matching `<turbo-frame id="post_123">` in the response, and swaps just that frame. The rest of the page stays put.

Edit `app/views/posts/edit.html.erb` to wrap its form in a matching frame:

```erb
<turbo-frame id="post_<%= @post.id %>">
  <%= render "form", post: @post %>
</turbo-frame>
```

Now editing happens in place.

### Turbo Streams

Streams update parts of the page in response to a server-side event — append a comment, remove a deleted post, replace a section. The server returns a `.turbo_stream` response:

```erb
<%# app/views/comments/create.turbo_stream.erb %>
<%= turbo_stream.append "comments", partial: "comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.replace "comment_form", partial: "comments/form", locals: { comment: Comment.new } %>
```

In `CommentsController`:

```ruby
def create
  @comment = @post.comments.build(comment_params)
  if @comment.save
    respond_to do |format|
      format.turbo_stream     # renders create.turbo_stream.erb
      format.html { redirect_to @post }
    end
  end
end
```

When the user submits the comment form, Turbo sends an Accept header asking for the stream response. The HTML page updates without a full reload — comment appears at the bottom, the form clears. Magic at first; mechanical once you see the wire format.

### Turbo Streams over WebSockets (broadcasts)

The same stream format works *across users* via WebSockets. In `app/models/post.rb`:

```ruby
class Post < ApplicationRecord
  broadcasts_to ->(post) { "posts" }, inserts_by: :prepend
end
```

Every time a Post is created/updated/destroyed, Rails broadcasts a Turbo Stream over the `posts` channel. Any browser subscribed to that channel updates in real time.

In `app/views/posts/index.html.erb`:

```erb
<%= turbo_stream_from "posts" %>
<div id="posts">
  <%= render @posts %>
</div>
```

Open two browser tabs. Create a post in one. Watch it appear in the other.

This is *Solid Cable* — Rails 8's replacement for Redis-backed Action Cable. No Redis needed; the broadcasts ride on your database.

### Stimulus

Stimulus controllers attach behavior to HTML via data attributes. Generate one:

```bash
bin/rails generate stimulus toggle
```

Edit `app/javascript/controllers/toggle_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}
```

Use it:

```erb
<div data-controller="toggle">
  <button data-action="click->toggle#toggle">Show details</button>
  <div data-toggle-target="content" class="hidden">
    Hidden content here.
  </div>
</div>
```

That's the entire Stimulus model. No build step beyond what Rails 8 ships. You write maybe ten lines of JS for a typical app.

## Forms

Rails 7+ uses `form_with`:

```erb
<%= form_with model: @post do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body %>
  <%= f.collection_select :author_id, Author.all, :id, :name %>
  <%= f.submit %>
<% end %>
```

`form_with model: @post`:
- Picks `POST /posts` for new records, `PATCH /posts/:id` for existing
- Generates field names like `post[title]` (matching strong params)
- Includes the CSRF token automatically

Display errors:

```erb
<% if @post.errors.any? %>
  <ul>
    <% @post.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
  </ul>
<% end %>
```

## Active Storage uploads

For file uploads (e.g., post cover images):

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

In `app/models/post.rb`:

```ruby
class Post < ApplicationRecord
  has_one_attached :cover_image
end
```

In the form:

```erb
<%= f.file_field :cover_image %>
```

In strong params:

```ruby
def post_params
  params.expect(post: [:title, :body, :author_id, :cover_image])
end
```

In the view:

```erb
<% if @post.cover_image.attached? %>
  <%= image_tag @post.cover_image %>
<% end %>
```

By default Active Storage stores files locally (`storage/`). For production switch to S3 or another cloud storage in `config/storage.yml`.

## Auth (Rails 8 built-in)

Rails 8 includes a built-in authentication generator. No Devise needed.

```bash
bin/rails generate authentication
bin/rails db:migrate
```

This creates:

- `User` model with `has_secure_password`
- `Session` model (for "remember me")
- `SessionsController` (login/logout)
- `RegistrationsController` (signup)
- `PasswordsController` (forgot/reset)
- Helpers: `authenticated?`, `current_user`, `require_authentication`

Edit `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  include Authentication
end
```

Skip auth where needed:

```ruby
class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[index]
end
```

Wire `current_user` into your blog:

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user      # was :author — rename or add a User belongs_to
end

# app/controllers/posts_controller.rb
def create
  @post = current_user.posts.build(post_params)
  ...
end
```

That's it — auth is now real. Users sign up, log in, log out, reset passwords. The default views are barebones HTML; customize them.

## ActionMailer

Send email from Rails:

```bash
bin/rails generate mailer Welcome
```

Creates `app/mailers/welcome_mailer.rb`:

```ruby
class WelcomeMailer < ApplicationMailer
  def greet(user)
    @user = user
    mail(to: user.email_address, subject: "Welcome to the blog!")
  end
end
```

Plus `app/views/welcome_mailer/greet.html.erb` and `greet.text.erb` (HTML and plain-text versions).

Send it (synchronously):

```ruby
WelcomeMailer.greet(user).deliver_now
```

Or queue it (next section):

```ruby
WelcomeMailer.greet(user).deliver_later
```

In development, Rails uses `letter_opener` if installed, or `:test` (just records mail without sending). In production, configure `config.action_mailer.smtp_settings` or use a service like SendGrid.

## Background jobs (Solid Queue)

Rails 8 ships with Solid Queue — a database-backed job queue. No Redis, no separate worker daemon to install (it runs as part of the Rails app process).

In `Gemfile` (already there from `rails new`):

```ruby
gem "solid_queue"
```

Generate a job:

```bash
bin/rails generate job DigestEmail
```

`app/jobs/digest_email_job.rb`:

```ruby
class DigestEmailJob < ApplicationJob
  queue_as :default

  def perform(user)
    posts = Post.where(author_id: user.id).where("created_at > ?", 1.week.ago)
    DigestMailer.with(user: user, posts: posts).digest.deliver_now
  end
end
```

Enqueue:

```ruby
DigestEmailJob.perform_later(user)
DigestEmailJob.set(wait: 1.hour).perform_later(user)
DigestEmailJob.set(wait_until: Time.current.tomorrow).perform_later(user)
```

To run jobs in development:

```bash
bin/jobs
```

## Caching (Solid Cache)

Rails 8 ships Solid Cache too — a database-backed cache store. Configure in `config/environments/production.rb`:

```ruby
config.cache_store = :solid_cache_store
```

Use:

```ruby
Rails.cache.fetch("expensive_query", expires_in: 1.hour) do
  Post.complex_aggregation
end
```

The block runs on first call; subsequent calls return the cached value until it expires.

### Fragment caching

Cache a piece of a view:

```erb
<% cache @post do %>
  <%= render @post %>
<% end %>
```

The cache key is auto-derived from `@post` — cache version, timestamps, partial name. When the post is updated, `cache_version` changes, the key changes, the cache misses, the new version renders.

### Russian doll caching

Nest cache calls. Inner caches stay valid even when the outer cache misses:

```erb
<% cache @post do %>
  <%= render @post %>
  <% @post.comments.each do |comment| %>
    <% cache comment do %>
      <%= render comment %>
    <% end %>
  <% end %>
<% end %>
```

Adding a comment invalidates the post's outer cache, but each existing comment's inner cache stays warm. Re-render is fast.

## Common pitfalls

- **Turbo Stream returning HTML status 200 when validation fails.** A failed `@comment.save` should re-render the form with `status: :unprocessable_entity`. Without that status, Turbo treats the response as success and the user sees no errors. The pattern:

  ```ruby
  def create
    @comment = @post.comments.build(comment_params)
    if @comment.save
      respond_to { |f| f.turbo_stream; f.html { redirect_to @post } }
    else
      render :new, status: :unprocessable_entity
    end
  end
  ```

- **Session vs cookie confusion.** `session[:user_id]` writes to the session store (server-trusted, signed). `cookies[:foo]` writes a raw cookie the user can read. `cookies.signed[:foo]` and `cookies.encrypted[:foo]` are the safe forms when you need a real cookie. Auth tokens go in `session` or `cookies.signed`, never in `cookies` directly.
- **Auth not enforcing CSRF on JSON endpoints.** `protect_from_forgery with: :null_session` in older code skips CSRF for API calls. Rails 8 defaults are stricter; don't relax them just because a JSON request fails. Send the CSRF token from your client instead.
- **`deliver_now` blocking the request.** `WelcomeMailer.greet(user).deliver_now` runs the SMTP call in the request thread. The user waits for it. Use `deliver_later` for any user-facing send; `deliver_now` belongs in tests and rake tasks.
- **Cache keys missing `cache_version` causing stale data.** `Rails.cache.fetch("posts/index") { Post.all.to_a }` never invalidates. Pass the model so the key auto-includes `updated_at`: `cache @post`, or use `Post.maximum(:updated_at)` in the key. When in doubt, render and check the log for `Read fragment` vs `Write fragment`.
- **Active Storage URLs expiring.** `url_for(post.cover_image)` returns a signed URL that expires (5 minutes by default). Don't paste it into emails or RSS feeds. Use `rails_blob_path(post.cover_image, only_path: true)` for a stable URL through your app, or set a longer expiry in `config.active_storage.urls_expire_in`.

## Security checklist

Before you point a domain at this app, walk this list. Every item is a real way Rails apps get owned.

- **CSRF on.** `protect_from_forgery with: :exception` is the Rails 8 default. Don't disable it. Forms made with `form_with` include the token automatically.
- **Parameter wrapping for JSON.** `wrap_parameters format: [:json]` (default) wraps top-level JSON params under the model name so strong params work the same for HTML and JSON.
- **Mass assignment closed via strong params.** `params.expect(post: [:title, :body])` (Rails 8) or `params.require(:post).permit(:title, :body)`. Never pass raw `params` to `update` or `create`.
- **SQL injection.** Always parameterize: `Post.where("title LIKE ?", "%#{q}%")`. Never `Post.where("title LIKE '%#{q}%'")` — that's a direct hole. The `?` placeholder is the rule.
- **XSS.** ERB escapes by default: `<%= user.name %>` is safe. `<%= raw user.name %>` and `user.name.html_safe` are not. Treat both as red flags — search your codebase for them and justify each one.
- **Session secret rotation.** `bin/rails credentials:edit` shows `secret_key_base`. Rotate it if it ever leaks; old sessions become invalid (users get logged out, which is what you want).
- **Password reset token TTL.** The Rails 8 auth generator sets a 15-minute window on reset tokens. Don't extend it. Short TTLs limit damage from a stolen email.
- **Rate limiting.** Add `rack-attack` for login throttling and per-IP request caps:

  ```ruby
  # config/initializers/rack_attack.rb
  Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/session" && req.post?
  end
  ```

- **HTTPS via `force_ssl`.** `config.force_ssl = true` in `production.rb` redirects http to https, sets HSTS, and marks cookies secure. Kamal's proxy terminates TLS for you; this flag tells Rails to insist on it.

## What you learned

| Concept | Key point |
|---|---|
| Turbo Drive | every link/form is intercepted, no full reload |
| `<turbo-frame>` | independent updateable region |
| `respond_to { format.turbo_stream }` | server returns stream actions |
| `broadcasts_to` | server-pushed updates over WebSockets (Solid Cable) |
| Stimulus controllers | data-attribute-driven JS, minimal code |
| `form_with model:` | one form helper for new and edit |
| Active Storage + `has_one_attached` | file uploads, with `cover_image.attached?` |
| `bin/rails generate authentication` | full auth out of the box, no Devise |
| `current_user`, `authenticated?` | helpers from the auth concern |
| `WelcomeMailer.greet(user).deliver_later` | async email through ActiveJob |
| `bin/jobs` | run Solid Queue's worker |
| `Rails.cache.fetch(key, expires_in:) { ... }` | cache aside |
| `<% cache @post do %>` | fragment caching with auto-derived keys |
| Russian doll caching | nested caches stay warm |

## Going deeper

- The Hotwire docs at `https://turbo.hotwired.dev`. Read the Turbo handbook end to end; it's short and the wire-format details matter when something doesn't update.
- The Stimulus handbook at `https://stimulus.hotwired.dev/handbook/introduction`. Same story — small, finishable in an evening.
- *Modern Front-End Development for Rails* (2nd ed.) by Noel Rappin. The book on Hotwire + Stimulus + import maps in Rails 7/8.
- Read the `solid_queue` source on GitHub. It's a small gem (a few thousand lines of Ruby) that shows what a database-backed job queue looks like under the hood. After Ch 6 + 10, you can read most of it.

## Exercises

1. **Hotwire-ify comments**: convert your comment form (Ch 11 ex 1) to use Turbo Streams. Posting a comment appends it to the list and clears the form, all without a page reload. Starter: `exercises/1_turbo_comments.md`.

2. **Stimulus toggle**: write a Stimulus controller that toggles the visibility of a post's `body` (so the index can show titles only, click to expand). Starter: `exercises/2_stimulus_toggle.md`.

3. **Cover images**: add cover image uploads to posts with Active Storage. Display in the index. Starter: `exercises/3_cover_images.md`.

4. **Auth wire-up**: install built-in auth, require it for new/create/edit/update/destroy on posts, allow unauthenticated for index/show. Starter: `exercises/4_auth.md`.

5. **Welcome email**: send a welcome email when a user registers. Use `deliver_later` so the request returns fast. Starter: `exercises/5_welcome_mail.md`.

6. **Cache the index**: fragment-cache the posts index. Verify with the Rails log that subsequent loads are cached. Starter: `exercises/6_cache_index.md`.
