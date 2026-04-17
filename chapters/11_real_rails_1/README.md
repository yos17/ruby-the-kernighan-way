# Chapter 11 — Real Rails: Models, Controllers, Views

You built the small version in Chapter 10. Now build the real one. This chapter starts a blog application with posts, comments, authors, and full CRUD. The point is not to admire Rails from a distance. The point is to watch the familiar pieces reappear in their production form.

If Rails feels big here, that is normal. Because Rails generates a lot of files, this chapter is a guided walkthrough. You do not need to read every file Rails creates. Follow the ones that move the app forward.

By the end of this chapter, the app will have:

- a `Post` model with validations
- `Author` and `Comment` associations
- CRUD controllers and views
- routes that read like the router you built last chapter
- enough real Rails structure that Chapter 12 can add Hotwire, auth, jobs, and caching

## Start a real app

Rails 8 requires Ruby 3.2+. You should have Ruby 3.4 from Chapter 0.

```bash
gem install rails -v "~> 8.0"
rails --version
# => Rails 8.0.x
```

A new Rails app:

```bash
cd ~/ruby-book
rails new blog --css tailwind
cd blog
bin/rails server
```

Visit `http://localhost:3000` — the Rails welcome page.

## Read the skeleton

```
blog/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   ├── helpers/
│   ├── jobs/
│   └── ...
├── config/
│   ├── routes.rb         # the URL → controller table
│   ├── database.yml
│   └── application.rb
├── db/
│   ├── migrate/          # schema migrations
│   └── seeds.rb
├── test/
├── Gemfile
└── Rakefile
```

This is the same shape as your `tiny_framework` from Ch 10:

| Tiny | Real Rails |
|---|---|
| `Router` with `get/post` blocks | `config/routes.rb` with the routes DSL |
| `class User < Model` | `app/models/user.rb` (`< ApplicationRecord`) |
| `User.find_by_name(...)` via `method_missing` | exact same — Active Record uses `method_missing` plus `define_method` caching |
| `Renderer.new(VIEWS_DIR)` | `ActionView` automatically rendering `.html.erb` files |
| WEBrick adapter | the bundled Puma server |

Rails adds a lot around the edges: migrations, validations, associations, eager loading, params, sessions, helpers, and a real database underneath it all. You do not need to hold every one of those abstractions in your head at once. Keep following the request path through routes, controller, model, and view. This chapter only needs the pieces that move the blog forward.

## Give the app its first real resource

Rails has *generators* — scripts that scaffold the boilerplate.

```bash
bin/rails generate scaffold Post title:string body:text published_at:datetime
bin/rails db:migrate
```

This created:

- `db/migrate/<ts>_create_posts.rb` — schema migration
- `app/models/post.rb` — the model class
- `app/controllers/posts_controller.rb` — full CRUD controller
- `app/views/posts/` — index/show/new/edit/_form views
- `test/` files
- A line in `config/routes.rb`: `resources :posts`

Visit `http://localhost:3000/posts`. You can already create, edit, and delete posts. That's the *scaffold*. From here we customize and learn how it all fits.

## Migrations

Open the migration file (`db/migrate/<ts>_create_posts.rb`):

```ruby
class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :body
      t.datetime :published_at

      t.timestamps    # adds created_at and updated_at
    end
  end
end
```

`bin/rails db:migrate` ran this. To roll back: `bin/rails db:rollback`.

To add a new column later, generate another migration:

```bash
bin/rails generate migration AddAuthorNameToPosts author_name:string
bin/rails db:migrate
```

The `AddXToY` naming convention is recognized by Rails — it generates the right `add_column :posts, :author_name, :string` automatically.

Always treat migrations as immutable history. Once a migration has been run on production, never edit it; write a new one.

## The model

`app/models/post.rb`:

```ruby
class Post < ApplicationRecord
end
```

That's all you need to start. `ApplicationRecord` (which inherits from `ActiveRecord::Base`) gives you the entire query DSL, validations, associations, and lifecycle callbacks.

Open the Rails console to play:

```bash
bin/rails console
```

```ruby
Post.create!(title: "First", body: "hello world")
Post.count                         # => 1
Post.all                           # => [#<Post id: 1, ...>]
Post.where(title: "First")         # => relation
Post.find_by(title: "First")       # => the post
Post.find(1)                       # => by id
Post.last
Post.order(created_at: :desc).limit(5)
```

Notice `Post.find_by(title: ...)` — this is the same `method_missing → define_method` trick from your `tiny_orm`, scaled up.

## Validations

Edit `app/models/post.rb`:

```ruby
class Post < ApplicationRecord
  validates :title, presence: true, length: { minimum: 3 }
  validates :body,  presence: true
end
```

In the console:

```ruby
post = Post.new(title: "ab")
post.valid?       # => false
post.errors.full_messages
# => ["Title is too short (minimum is 3 characters)", "Body can't be blank"]
post.save         # => false
post.save!        # raises ActiveRecord::RecordInvalid
```

`validates` runs at `save` time. The `!` versions raise; the non-bang versions return `false` and let you check `errors`.

## Associations

A blog has authors and comments. Generate them:

```bash
bin/rails generate model Author name:string email:string
bin/rails generate model Comment body:text post:references author:references
bin/rails generate migration AddAuthorRefToPosts author:references
bin/rails db:migrate
```

`post:references` adds an `author_id` column with a foreign key and an index — Rails knows what you mean.

Edit the models:

```ruby
# app/models/author.rb
class Author < ApplicationRecord
  has_many :posts
  has_many :comments

  validates :name, :email, presence: true
end

# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :author
  has_many :comments, dependent: :destroy

  validates :title, presence: true, length: { minimum: 3 }
  validates :body,  presence: true
end

# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :author

  validates :body, presence: true
end
```

`has_many :posts` gives `Author#posts` — a relation you can chain (`author.posts.order(:created_at)`).

`belongs_to :author` gives `Post#author` and `Post#author=`. By default it requires the association — saving a post without an author raises.

`dependent: :destroy` deletes a post's comments when the post is deleted. (Other options: `:nullify`, `:restrict_with_error`.)

In the console:

```ruby
author = Author.create!(name: "Yosia", email: "y@example.com")
post = author.posts.create!(title: "Hello", body: "first post")
post.comments.create!(body: "great post!", author: author)

author.posts.count          # => 1
post.comments.count         # => 1
post.author.name            # => "Yosia"
```

## N+1 and eager loading

The classic Rails performance bug. Loading every post's author causes N+1 queries:

```ruby
Post.all.each { |p| puts p.author.name }
# => SELECT * FROM posts
# => SELECT * FROM authors WHERE id = 1
# => SELECT * FROM authors WHERE id = 2
# ...
```

Fix with `includes`:

```ruby
Post.includes(:author).each { |p| puts p.author.name }
# => SELECT * FROM posts
# => SELECT * FROM authors WHERE id IN (1, 2, ...)
```

Two queries instead of N+1. Always `includes` an association you'll touch in a loop.

The `bullet` gem (development-only) flags N+1s automatically. Add it to your Gemfile:

```ruby
group :development do
  gem "bullet"
end
```

## Scopes

Scopes are reusable query fragments:

```ruby
class Post < ApplicationRecord
  scope :published, -> { where.not(published_at: nil) }
  scope :recent,    -> { order(created_at: :desc) }
end

Post.published.recent.limit(5)
```

Reads almost like English. Compose them.

## A short database detour

A few rules carry most of the weight.

*First normal form*: each column holds one value; no comma-separated lists in a `tags` string. If you need many tags per post, make a `tags` table and a `post_tags` join. Searching `WHERE tags LIKE '%ruby%'` cannot use an index; `WHERE tag = 'ruby'` can.

*Denormalize on purpose*. Strict normalization minimizes redundancy; production schemas sometimes duplicate a value (an author's display name copied onto each post) to avoid a join on a hot read path. Do it when you've measured a real cost, not preemptively.

*Indexes*. Primary keys are indexed automatically. Foreign keys are not — but Rails' `t.references :author` adds an index for you because almost every foreign key gets queried (`Author#posts` does `WHERE posts.author_id = ?`). For multi-column queries (`WHERE author_id = ? AND published_at > ?`), add a composite index: `add_index :posts, [:author_id, :published_at]`. Column order matters — put the most selective column first, or the column you'll often query alone.

*`EXPLAIN` shows query plans*. In the Rails console: `Post.where(author_id: 5).explain`. The output tells you whether the database is using an index (`Index Scan`) or scanning the whole table (`Seq Scan`). When a query gets slow, this is your first stop. (Postgres has the richest output; SQLite's is terse but readable.)

## Controllers

Open `app/controllers/posts_controller.rb`. The scaffold generated:

```ruby
class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy]

  def index
    @posts = Post.all
  end

  def show; end

  def new
    @post = Post.new
  end

  def edit; end

  def create
    @post = Post.new(post_params)
    if @post.save
      redirect_to @post, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_url, notice: "Post was successfully destroyed.", status: :see_other
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.expect(post: [:title, :body, :published_at, :author_id])
  end
end
```

What to notice.

`before_action :set_post, only: %i[show edit update destroy]` — runs `set_post` before those four actions. Saves writing `@post = Post.find(params[:id])` four times.

`@post = Post.find(params[:id])` — instance variables in controllers are visible in views. Same `binding`-trick you used in `tiny_renderer`.

`params.expect(post: [...])` — Rails 8's *strong parameters*. Only allows the listed keys through; rejects anything else. Without this, an attacker could POST `?post[admin]=true` and update fields you didn't intend.

`render :new, status: :unprocessable_entity` — when validation fails, render the `new` template again with the errored `@post`. Status 422 tells Turbo (Ch 12) to swap the form correctly.

`redirect_to @post` — Rails uses URL helpers — `@post` becomes `post_url(@post)` because of the routing convention. Same for `posts_url`.

## Routes

`config/routes.rb`:

```ruby
Rails.application.routes.draw do
  resources :posts
  root "posts#index"
end
```

`resources :posts` creates the standard 7 routes:

| HTTP | URL | Controller#action |
|---|---|---|
| GET | `/posts` | `posts#index` |
| GET | `/posts/new` | `posts#new` |
| POST | `/posts` | `posts#create` |
| GET | `/posts/:id` | `posts#show` |
| GET | `/posts/:id/edit` | `posts#edit` |
| PATCH | `/posts/:id` | `posts#update` |
| DELETE | `/posts/:id` | `posts#destroy` |

The corresponding URL helpers (`posts_url`, `new_post_url`, `post_url(post)`, `edit_post_url(post)`) come for free.

To see all routes: `bin/rails routes`.

For nested resources:

```ruby
resources :posts do
  resources :comments
end
# => /posts/:post_id/comments, etc.
```

## Why the conventions matter

Rails calls itself "convention over configuration." Concretely that means: if you name files the way Rails expects, you write zero glue code. If you don't, you write configuration to bridge the gap. The conventions:

- **File naming follows class naming.** `UsersController` lives in `app/controllers/users_controller.rb`. `BlogPost` lives in `app/models/blog_post.rb`. Zeitwerk turns the constant `UsersController` into the path `users_controller.rb` and loads it on first reference. Break the convention and autoloading raises.
- **`users` plural for table, route, controller; `user` singular for model.** A row is one user; a controller manages the collection. So `User` (model class), `users` (table), `users_controller.rb`, `/users` (route). ActiveSupport's inflector handles the pluralization (`Inflector.pluralize("person") == "people"`).
- **Seven RESTful actions, no more.** `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`. They cover *list*, *display one*, *show form to add*, *handle submitted add*, *show form to edit*, *handle submitted edit*, *delete*. Why exactly seven: forms need a GET (`new`, `edit`) to render and a POST/PATCH/DELETE to submit, plus list/display reads. Anything else is either a different resource (extract it) or not REST (use a custom route — sparingly).
- **REST verbs map to actions.** `GET /posts` → `index`, `POST /posts` → `create`, `GET /posts/:id` → `show`, `PATCH /posts/:id` → `update`, `DELETE /posts/:id` → `destroy`. The HTTP method *is* the dispatch.
- **Instance variables flow controller → view.** `@post = Post.find(...)` in the controller is visible as `@post` in the view. Same `binding`-passing trick from `tiny_renderer`. Local variables (`post = ...`) do not flow — they vanish at the end of the action. This is the only "magic" here, and it's the same magic you wrote.

The payoff: a developer reading your app knows where every file is without asking. The cost: deviating from convention is expensive — name a controller `UserManagement` and you fight Rails for the rest of the project.

## Views

`app/views/posts/index.html.erb`:

```erb
<% content_for :title, "Posts" %>

<h1>Posts</h1>

<div id="posts">
  <% @posts.each do |post| %>
    <%= render post %>
    <p><%= link_to "Show this post", post %></p>
  <% end %>
</div>

<%= link_to "New post", new_post_path %>
```

What to notice.

`<%= render post %>` — render the partial `app/views/posts/_post.html.erb` for this post. Convention: `_partialname.html.erb` for partials, `render @post` (or `render @posts`) for plural.

`<%= link_to "Show this post", post %>` — generates `<a href="/posts/3">Show this post</a>`. Works because Rails knows `post` becomes `post_url(post)`.

`<% content_for :title, "Posts" %>` — set a value the layout can `yield`.

The partial `app/views/posts/_post.html.erb`:

```erb
<div id="<%= dom_id post %>">
  <p><strong>Title:</strong> <%= post.title %></p>
  <p><strong>Body:</strong> <%= post.body %></p>
</div>
```

`dom_id post` returns `post_3` — used for Hotwire targeting in Ch 12.

The layout `app/views/layouts/application.html.erb` wraps every page. It's a normal ERB template with `<%= yield %>` where the per-page content goes.

## Helpers

`app/helpers/posts_helper.rb`:

```ruby
module PostsHelper
  def post_status_label(post)
    if post.published_at
      "Published #{time_ago_in_words(post.published_at)} ago"
    else
      "Draft"
    end
  end
end
```

Use in views: `<%= post_status_label(post) %>`. Helpers are for view logic that's awkward in templates but doesn't belong in the model.

## Common pitfalls

- **Forgetting `bin/rails db:migrate`.** Running a generator scaffolds a migration file but does not apply it. The next `Post.create` raises `PG::UndefinedTable` (or the SQLite equivalent). After every `generate model` or `generate migration`, run `bin/rails db:migrate`. Use `bin/rails db:migrate:status` to see what's pending.
- **Editing a migration that already ran in production — never.** Once a migration is in `schema_migrations` on a deployed environment, editing it does not re-run it; you've created a schema mismatch between machines that will bite weeks later. Write a *new* migration that fixes the prior one. The only safe edit-in-place case is a migration you wrote five minutes ago that has only run on your laptop.
- **`before_action` order surprises.** Filters run in declaration order, top to bottom. `before_action :authenticate_user!` followed by `before_action :set_post` means `set_post` runs *after* auth — usually what you want. Reverse them and an unauthenticated request still hits the database. `skip_before_action` and `only:`/`except:` further complicate the order; print the chain with `_process_action_callbacks` if you're confused.
- **`params` is `ActionController::Parameters`, not `Hash`.** `params[:id]` and `params["id"]` both work (HashWithIndifferentAccess heritage), but `params.to_h` raises unless you've called `permit`. Don't pattern-match `params` against a `Hash` shape; convert with `.to_unsafe_h` only when you genuinely don't need filtering.
- **`dependent: :destroy` vs database `ON DELETE CASCADE`.** `:destroy` runs Ruby callbacks per child (slow on large sets, but fires `before_destroy`). `ON DELETE CASCADE` (set in a migration with `foreign_key: { on_delete: :cascade }`) is one SQL statement, fast, no callbacks. Pick based on whether you need the callbacks. Mixing both is fine — Rails deletes first, the DB cleans up anything the app missed.
- **Missing `inverse_of` and N+1 in disguise.** When `Post belongs_to :author` and `Author has_many :posts` use a non-standard foreign key or scope, Rails can't infer the inverse. Reading `post.author.posts.first.author` then issues an extra query because `posts.first.author` is a fresh object that doesn't know it came from the `author` you started with. `inverse_of: :author` (and its mirror) tells Rails they're two views of the same record. With standard names Rails infers it; with custom `class_name:` or `foreign_key:`, set it explicitly.

## What you learned

| Concept | Key point |
|---|---|
| `rails new app` | scaffolds a complete app skeleton |
| `bin/rails generate scaffold` | generates model + controller + views + routes for a resource |
| Migrations (`bin/rails db:migrate`) | versioned schema changes; never edit a run migration |
| `ApplicationRecord` model | gives you query DSL, validations, callbacks, associations |
| `Post.where(...)`, `find_by`, `find` | Active Record query API |
| `validates :col, presence: true` | declarative validations |
| `has_many` / `belongs_to` / `dependent: :destroy` | associations |
| N+1 and `includes` | the classic perf bug; eager-load the association |
| `scope :name, -> { ... }` | reusable query fragments |
| `before_action :method, only: [...]` | controller filters |
| Strong params (`params.expect(...)`) | whitelist input |
| `resources :posts` | the 7 standard CRUD routes |
| `bin/rails routes` | print every route the app handles |
| `<%= render post %>` | partial rendering convention |
| `<%= link_to text, post %>` | URL helpers from model objects |
| `dom_id post` | unique HTML id for a record (used by Turbo) |

## Exercises

These exercises modify your `blog` app from this chapter. Make commits as you go.

1. **Add Comment scaffolding under Post**: `bin/rails generate scaffold Comment body:text post:references author:references` and adjust routes to nest comments under posts. Starter: `exercises/1_comments.md`.

2. **Search**: add a `?q=...` parameter to `posts#index` that filters posts by title (case-insensitive). Hint: `where("title ILIKE ?", "%#{params[:q]}%")` for Postgres, or `where("title LIKE ?", ...)` for SQLite. Better: define a scope. Starter: `exercises/2_search.md`.

3. **Author dashboard**: add a `/authors/:id/dashboard` route that shows an author's recent posts, comment count, etc. Reuse partials. Starter: `exercises/3_dashboard.md`.

4. **Pagination**: install `pagy` (or `kaminari`), paginate the posts index, 10 per page. Starter: `exercises/4_pagination.md`.

5. **Soft delete**: add a `discarded_at` timestamp to Post. Override `destroy` to set it instead of deleting. Add a default scope to skip discarded. Starter: `exercises/5_soft_delete.md`.

6. **Tests**: write a test for `PostsController#create` — a valid post creates the record; an invalid one returns 422 and re-renders the new template. Use the generated `test/controllers/posts_controller_test.rb` as a starting point. Starter: `exercises/6_tests.md`.
