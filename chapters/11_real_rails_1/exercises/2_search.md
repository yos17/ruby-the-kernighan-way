# Exercise 2 — Search posts by title

In `app/models/post.rb`:

```ruby
scope :search, ->(q) {
  return all if q.blank?
  where("title LIKE ?", "%#{q}%")
}
```

In `app/controllers/posts_controller.rb`:

```ruby
def index
  @posts = Post.search(params[:q]).order(created_at: :desc)
end
```

In `app/views/posts/index.html.erb`:

```erb
<%= form_with url: posts_path, method: :get do |f| %>
  <%= f.text_field :q, value: params[:q], placeholder: "Search..." %>
  <%= f.submit "Search" %>
<% end %>
```

Note: `where("title LIKE ?", "%#{q}%")` — the `?` placeholder is **essential**. NEVER do `where("title LIKE '%#{q}%'")` — that's a SQL injection. Rails 12.5 makes the latter raise; older versions silently let it through.
