# Exercise 1 — Hotwire-ify comments

In `app/views/posts/show.html.erb`, wrap the comments list and form in unique IDs:

```erb
<turbo-frame id="comments">
  <div id="comments_list">
    <% @post.comments.includes(:author).each do |c| %>
      <%= render c %>
    <% end %>
  </div>

  <div id="comment_form">
    <%= render "comments/form", post: @post, comment: @post.comments.new %>
  </div>
</turbo-frame>
```

In `app/views/comments/_comment.html.erb`:

```erb
<div id="<%= dom_id comment %>">
  <strong><%= comment.author.name %>:</strong> <%= comment.body %>
</div>
```

Create `app/views/comments/create.turbo_stream.erb`:

```erb
<%= turbo_stream.append "comments_list", partial: "comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.update "comment_form", partial: "comments/form", locals: { post: @post, comment: Comment.new } %>
```

In `CommentsController#create`:

```ruby
def create
  @post = Post.find(params[:post_id])
  @comment = @post.comments.build(comment_params)
  @comment.author = current_user || Author.first
  if @comment.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end
end
```

Now posting a comment appends it to the list AND resets the form, no page reload.
