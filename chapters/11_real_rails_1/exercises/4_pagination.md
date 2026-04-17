# Exercise 4 — Pagination with pagy

Add to Gemfile:

```ruby
gem "pagy", "~> 9"
```

```bash
bundle install
```

In `app/controllers/application_controller.rb`:

```ruby
include Pagy::Backend
```

In `app/helpers/application_helper.rb`:

```ruby
include Pagy::Frontend
```

In `app/controllers/posts_controller.rb`:

```ruby
def index
  @pagy, @posts = pagy(Post.order(created_at: :desc), items: 10)
end
```

In `app/views/posts/index.html.erb`, add at the bottom:

```erb
<%== pagy_nav(@pagy) %>
```

`pagy` is the lightest pagination gem in Ruby. Other options: `kaminari` (more features, slower), `will_paginate` (older, still common).
