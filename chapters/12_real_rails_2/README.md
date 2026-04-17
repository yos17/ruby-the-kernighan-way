# Chapter 12 — Real Rails: Hotwire, Forms, Auth, Jobs, Caching

Chapter 11 gave you a working blog. This chapter makes it feel like an application you could keep. We add five things: pages that update without full reloads, a little browser-side behavior, file uploads, authentication, and the background plumbing that keeps requests fast.

The order matters. First make the interface feel responsive. Then protect write actions. Then move slow work out of the request. Then cache what is expensive.

## New Rails ideas you'll meet in this chapter

This is where Rails stops looking like MVC and starts looking like a platform.

- **Hotwire** — Rails's "HTML over the wire" umbrella. Moves updates over the network as HTML fragments instead of JSON, so you rarely need a JS framework.
- **Turbo Drive** — intercepts link clicks and form submissions, fetches the next page, and swaps the `<body>` — all without a full reload. On by default.
- **Turbo Frames** — tag a region with `<turbo-frame id="...">` and updates to that frame replace only that region, not the whole page.
- **Turbo Streams** — server-pushed HTML fragments over WebSockets. Great for live comments, notifications, anything that has to update for other users.
- **Stimulus** — a tiny JavaScript framework for sprinkling in behavior. Controllers attach to DOM elements via `data-controller="name"`.
- **Active Storage** — file uploads, built in. `has_one_attached :cover` on a model and Rails handles uploads, storage, URLs.
- **Active Job** — background jobs. `SomeJob.perform_later(args)` hands work to a queue (Solid Queue in Rails 8, Sidekiq elsewhere). Keeps slow work out of the request cycle.
- **Authentication** — Rails 8 generates `bin/rails g authentication` for a sessions-based setup; older apps use Devise. Either way: users, passwords, password resets.
- **CSRF (Cross-Site Request Forgery)** — Rails automatically adds a token to forms and rejects POST requests without it. Don't disable it.
- **Action Mailer** — generates email templates and delivers them, usually via an Active Job so requests stay fast.
- **Fragment caching** — `<% cache post do %>` wraps a bit of view in a cache keyed by the post. Re-uses rendered HTML until the underlying record changes.

## The build

By the end of the chapter, the blog will have:

- comments that appear without a full page reload
- an in-page toggle built with Stimulus
- cover image uploads for posts
- sign-in and password reset
- mail sent through jobs
- cached fragments for the expensive parts

## Hotwire — make the blog feel live

Hotwire is the combination of Turbo and Stimulus. Turbo handles most of the page updates. Stimulus handles the small pieces of behavior that are easier in JavaScript than in HTML alone.

### Turbo Drive

Turbo Drive is the default. Links and forms are intercepted, the server sends back HTML, and Turbo swaps the page content without a full reload. You can see it immediately: click around the blog and notice that navigation feels faster even though the server still renders every page.

To opt out for one link or form, add `data: { turbo: false }`.

```erb
<%= link_to "Manual", "/manual.pdf", data: { turbo: false } %>
```

### Turbo Frames

Use a Turbo Frame when one region of a page should update on its own. Editing a post inline is a good first use.

```erb
<turbo-frame id="post_<%= post.id %>">
  <%= post.title %>
  <%= link_to "Edit", edit_post_path(post) %>
</turbo-frame>
```

Then return a matching frame from the edit view:

```erb
<turbo-frame id="post_<%= @post.id %>">
  <%= render "form", post: @post %>
</turbo-frame>
```

Now the edit form appears in place instead of replacing the whole page.

### Turbo Streams

Use Turbo Streams when one action should update several parts of the page. Comments are the obvious example: append the new comment to the list and reset the form.

```erb
<%# app/views/comments/create.turbo_stream.erb %>
<%= turbo_stream.append "comments", partial: "comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.replace "comment_form", partial: "comments/form", locals: { comment: Comment.new } %>
```

In the controller:

```ruby
def create
  @comment = @post.comments.build(comment_params)

  if @comment.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post, notice: "Comment added." }
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

The important detail is the failure case. If validation fails, return `status: :unprocessable_entity`. Without it, Turbo treats the response as success and the user gets no useful feedback.

### Broadcasts

Turbo Streams also work across browser tabs and across users. If the posts index should update when a new post is published, subscribe the page:

```erb
<%= turbo_stream_from "posts" %>
<div id="posts">
  <%= render @posts %>
</div>
```

Then broadcast from the model:

```ruby
class Post < ApplicationRecord
  broadcasts_to ->(_post) { "posts" }, inserts_by: :prepend
end
```

Create a post in one tab. It appears in the other. The behavior is no longer mysterious once you have seen the stream template and the subscription side by side.

### Stimulus

Turbo gets you far without writing JavaScript. Stimulus covers the cases where a few lines of JavaScript are still the cleanest answer.

Generate a controller:

```bash
bin/rails generate stimulus toggle
```

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}
```

Attach it in the view:

```erb
<div data-controller="toggle">
  <button data-action="click->toggle#toggle">Show details</button>
  <div data-toggle-target="content" class="hidden">
    Hidden content here.
  </div>
</div>
```

That is the whole Stimulus model: a small controller, named targets, and actions wired by data attributes.

## Forms

`form_with` is the standard form helper. It chooses the route, HTTP method, field names, and CSRF token automatically from the model object you pass in.

```erb
<%= form_with model: @post do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body %>
  <%= f.collection_select :author_id, Author.all, :id, :name %>
  <%= f.submit %>
<% end %>
```

Show validation errors near the form instead of making the user guess:

```erb
<% if @post.errors.any? %>
  <ul>
    <% @post.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
  </ul>
<% end %>
```

The form helper is doing more work than it first appears to: it lines up the generated field names with strong params and keeps the request safe by including the authenticity token.

## Active Storage — upload cover images

For file uploads, install Active Storage:

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

Attach one image to each post:

```ruby
class Post < ApplicationRecord
  has_one_attached :cover_image
end
```

Add the file field to the form:

```erb
<%= f.file_field :cover_image %>
```

Permit it in strong params:

```ruby
def post_params
  params.expect(post: [:title, :body, :author_id, :cover_image])
end
```

Render it in the view:

```erb
<% if @post.cover_image.attached? %>
  <%= image_tag @post.cover_image %>
<% end %>
```

Development stores files locally under `storage/`. In production, switch to S3 or another service when local disk stops being enough.

## Authentication — protect write actions

Rails 8 ships with an authentication generator. It gives you sign-in and password reset. It does not build a public sign-up flow for you.

```bash
bin/rails generate authentication
bin/rails db:migrate
```

The generator adds models, controllers, views, routes, and mailers for the basic authentication flow. Include the concern in `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  include Authentication
end
```

Then protect the write actions on posts while keeping the public pages open:

```ruby
class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
end
```

For the chapter build, creating a user in the console is enough:

```ruby
User.create!(email_address: "you@example.com", password: "secret123")
```

Then sign in at `/session/new`.

If you want public registration, wire it yourself after the generator run. That matches the real shape of most apps: sign-in is standard; sign-up is application-specific.

## Action Mailer — send a welcome email

Generate a mailer:

```bash
bin/rails generate mailer Welcome
```

```ruby
class WelcomeMailer < ApplicationMailer
  def greet(user)
    @user = user
    mail(to: user.email_address, subject: "Welcome to the blog!")
  end
end
```

Send it immediately:

```ruby
WelcomeMailer.greet(user).deliver_now
```

Or queue it:

```ruby
WelcomeMailer.greet(user).deliver_later
```

Use `deliver_later` for user-facing requests. The request should return before the SMTP conversation begins.

## Background jobs — move slow work out of the request

Rails 8 uses Solid Queue as the default durable job backend in production. If you want local development to behave the same way, configure it there too and prepare the queue database:

```ruby
# config/environments/development.rb
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
```

```bash
bin/rails db:prepare
bin/jobs start
```

Generate a job:

```bash
bin/rails generate job WelcomeEmail
```

```ruby
class WelcomeEmailJob < ApplicationJob
  queue_as :default

  def perform(user)
    WelcomeMailer.greet(user).deliver_now
  end
end
```

Enqueue it:

```ruby
WelcomeEmailJob.perform_later(user)
WelcomeEmailJob.set(wait: 1.hour).perform_later(user)
```

Jobs still need a worker process. Rails gives you that process with `bin/jobs start`; you do not need Redis or a separate queueing product just to get started.

## Caching — keep the expensive parts warm

Rails 8 enables Solid Cache by default. It is a database-backed cache store, which is a good fit for the small-application shape this book has been building toward.

```ruby
Rails.cache.fetch("expensive_query", expires_in: 1.hour) do
  Post.complex_aggregation
end
```

That is cache-aside: compute once, reuse until expiry.

### Fragment caching

Cache a rendered piece of a page:

```erb
<% cache @post do %>
  <%= render @post %>
<% end %>
```

The key tracks the post version, so an updated post invalidates the cached fragment naturally.

### Russian doll caching

Nest cache calls when a large page contains many smaller stable pieces:

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

If one comment changes, only that fragment goes cold. The rest stay warm.

## Common pitfalls

- **Turbo failure responses without `422`.** Validation errors need `status: :unprocessable_entity` or the browser gets a successful response with no useful state change.
- **Treating the auth generator as a full user system.** It gives sign-in and reset-password flow. Public registration is still your code.
- **Using `deliver_now` in the request path.** The user waits on the mail provider.
- **Forgetting the worker process.** `perform_later` enqueues work; nothing runs until `bin/jobs start` is running somewhere.
- **Hand-made cache keys that never expire.** `Rails.cache.fetch("posts/index")` stays stale unless you version it yourself.
- **Dropping signed Active Storage URLs into long-lived places.** For emails or feeds, prefer URLs routed through your app instead of short-lived direct URLs.

## Security checklist

Before you put a domain on the app, verify these:

- **CSRF is still on.** `form_with` includes the token automatically; do not disable forgery protection to make one broken request pass.
- **Strong params are tight.** `params.expect(post: [...])` or `permit` only the fields you actually want writable.
- **Queries are parameterized.** `Post.where("title LIKE ?", "%#{q}%")`, never string interpolation into SQL.
- **ERB escaping stays on.** Treat `raw` and `html_safe` as suspicious until proven necessary.
- **`force_ssl` is enabled in production.** Cookies and redirects should assume HTTPS from day one.
- **Password reset links stay short-lived.** The generated authentication flow uses a short token lifetime; keep it that way.

## What you learned

| Concept | Key point |
|---|---|
| Turbo Drive | page navigation stays server-rendered but feels faster |
| Turbo Frames | one region can update without replacing the whole page |
| Turbo Streams | one action can update several regions at once |
| Stimulus | small JavaScript behavior lives beside the HTML |
| `form_with model:` | route, method, names, and CSRF line up automatically |
| Active Storage | uploads attach to models with a small API |
| `bin/rails generate authentication` | sign-in and password reset arrive quickly |
| `deliver_later` | mail belongs in a job, not in the request path |
| `bin/jobs start` | queued work needs a worker process |
| Fragment caching | cache rendered view pieces, not just raw values |

## Going deeper

- Read the Turbo handbook: https://turbo.hotwired.dev
- Read the Stimulus handbook: https://stimulus.hotwired.dev/handbook/introduction
- Read the Rails security guide section on the authentication generator: https://guides.rubyonrails.org/security.html
- Read the Active Job guide sections on Solid Queue: https://guides.rubyonrails.org/active_job_basics.html

## Exercises

1. **Hotwire-ify comments**: convert your comment form (Ch 11 ex 1) to use Turbo Streams. Posting a comment appends it to the list and clears the form, all without a page reload. Starter: `exercises/1_turbo_comments.md`.

2. **Stimulus toggle**: write a Stimulus controller that toggles the visibility of a post's `body` so the index can show titles only, then expand on click. Starter: `exercises/2_stimulus_toggle.md`.

3. **Cover images**: add cover image uploads to posts with Active Storage. Display them in the index. Starter: `exercises/3_cover_images.md`.

4. **Auth wire-up**: install built-in auth, require it for new/create/edit/update/destroy on posts, allow unauthenticated access for index/show. Starter: `exercises/4_auth.md`.

5. **Welcome email**: send a welcome email when a user registers. Use `deliver_later` so the request returns fast. Starter: `exercises/5_welcome_mail.md`.

6. **Cache the index**: fragment-cache the posts index. Verify in the Rails log that subsequent loads are cached. Starter: `exercises/6_cache_index.md`.
