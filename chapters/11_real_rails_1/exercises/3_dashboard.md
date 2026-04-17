# Exercise 3 — Author dashboard

Add a custom action to AuthorsController.

```ruby
# config/routes.rb
resources :authors do
  member do
    get :dashboard
  end
end

# app/controllers/authors_controller.rb
def dashboard
  @author = Author.find(params[:id])
  @recent_posts = @author.posts.order(created_at: :desc).limit(5)
  @comment_count = @author.comments.count
end
```

`app/views/authors/dashboard.html.erb`:

```erb
<h1><%= @author.name %>'s dashboard</h1>
<p>Comments: <%= @comment_count %></p>

<h2>Recent posts</h2>
<%= render @recent_posts %>
```

Note: `render @recent_posts` looks for `_post.html.erb` partial — re-uses the partial from the posts views. Convention over configuration.
