# Exercise 5 — Soft delete with discarded_at

```bash
bin/rails generate migration AddDiscardedAtToPosts discarded_at:datetime
bin/rails db:migrate
```

In `app/models/post.rb`:

```ruby
class Post < ApplicationRecord
  scope :kept, -> { where(discarded_at: nil) }
  scope :discarded, -> { where.not(discarded_at: nil) }
  default_scope { kept }   # USE WITH CAUTION

  def discard!
    update!(discarded_at: Time.current)
  end

  def undiscard!
    update!(discarded_at: nil)
  end
end
```

In `app/controllers/posts_controller.rb`:

```ruby
def destroy
  @post.discard!
  redirect_to posts_url, notice: "Post discarded", status: :see_other
end
```

**Caveats:**

- `default_scope` is a footgun — every query everywhere now filters by `discarded_at IS NULL`. Sometimes that's what you want; sometimes a query meant to find a discarded post mysteriously returns nothing.
- An admin "trash" view needs to bypass: `Post.unscoped.discarded`.
- Heavy alternative: the `discard` gem provides a more disciplined version of this pattern.

Soft deletes are a good *feature* but a known *footgun*. Add tests.
