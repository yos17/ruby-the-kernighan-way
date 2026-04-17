# Exercise 4 — Built-in auth wired into posts

```bash
bin/rails generate authentication
bin/rails db:migrate
```

In `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  include Authentication
end
```

In `app/controllers/posts_controller.rb`:

```ruby
allow_unauthenticated_access only: %i[index show]
before_action :set_post, only: %i[show edit update destroy]

def create
  @post = current_user.posts.build(post_params)
  ...
end
```

In `app/models/post.rb`:

```ruby
belongs_to :user, class_name: "User", foreign_key: "user_id", inverse_of: :posts
```

(Or rename `author_id` to `user_id` via a migration if you want to ditch the separate Author model.)

In `app/models/user.rb` (auto-generated):

```ruby
has_many :posts, dependent: :destroy
has_many :comments, dependent: :destroy
```

Now: anonymous visitors can browse, only signed-in users can write.
