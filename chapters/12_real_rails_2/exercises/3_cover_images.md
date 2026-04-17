# Exercise 3 — Cover images via Active Storage

Install (if not already):

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

In `app/models/post.rb`:

```ruby
has_one_attached :cover_image
```

In `app/views/posts/_form.html.erb`:

```erb
<div class="field">
  <%= form.label :cover_image %>
  <%= form.file_field :cover_image, accept: "image/*" %>
</div>
```

In `app/controllers/posts_controller.rb`:

```ruby
def post_params
  params.expect(post: [:title, :body, :author_id, :cover_image])
end
```

In `app/views/posts/_post.html.erb`:

```erb
<% if post.cover_image.attached? %>
  <%= image_tag post.cover_image, style: "max-width: 400px" %>
<% end %>
```

For production, switch from local storage to S3 or similar in `config/storage.yml` and `config/environments/production.rb`.
