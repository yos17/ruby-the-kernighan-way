# Chapter 11 — Real Rails: Models, Controllers, Views

You've built a tiny framework in Ch 10. Real Rails is the polished, battle-tested version of the same shape: a router, models with a query DSL, controllers that handle requests, views that render HTML. This chapter and the next walk you through building a complete blog application — posts, comments, authors, full CRUD. By the end of Ch 12 you'll have an app you'd be proud to deploy.

Because Rails generates a lot of files, this chapter is a *guided walkthrough*: you run commands, edit a few key files, and end up with a working app. The exercises at the end ask you to extend it.

## Setup

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

## What `rails new` made

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

What Rails adds that yours doesn't: migrations, validations, associations, eager loading, request lifecycle (params/sessions/cookies/CSRF), forms, helpers, asset pipeline, the database. We'll meet most of those today.

## Generating the Post resource

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
