# Exercise 1 — Comments scaffolding nested under Posts

```bash
bin/rails generate scaffold Comment body:text post:references author:references
bin/rails db:migrate
```

Edit `config/routes.rb`:

```ruby
resources :posts do
  resources :comments, only: %i[create destroy]
end
```

Edit `CommentsController#create` to use the nested route:

```ruby
def create
  @post = Post.find(params[:post_id])
  @comment = @post.comments.build(comment_params)
  @comment.author = Author.first  # or current_user when you add auth in Ch 12
  if @comment.save
    redirect_to @post, notice: "Comment posted"
  else
    redirect_to @post, alert: @comment.errors.full_messages.join(", ")
  end
end
```

Add a comment form to `app/views/posts/show.html.erb`:

```erb
<%= form_with model: [@post, @post.comments.new] do |f| %>
  <%= f.text_area :body %>
  <%= f.submit "Comment" %>
<% end %>

<h2>Comments</h2>
<% @post.comments.includes(:author).each do |c| %>
  <p><strong><%= c.author.name %>:</strong> <%= c.body %></p>
<% end %>
```

Notice the `.includes(:author)` — without it, you'd N+1 across comments.
