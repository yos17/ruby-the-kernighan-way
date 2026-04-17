# Exercise 6 — Cache the posts index

In `app/views/posts/index.html.erb`:

```erb
<% cache "posts_index_#{Post.maximum(:updated_at).to_i}" do %>
  <h1>Posts</h1>
  <%= render @posts %>
<% end %>
```

Alternative — cache each post individually (Russian doll):

```erb
<%= render @posts %>
```

And in `_post.html.erb`:

```erb
<% cache post do %>
  <h3><%= link_to post.title, post %></h3>
  <p><%= post.body.truncate(100) %></p>
<% end %>
```

Configure caching in development to test it:

```bash
bin/rails dev:cache
```

Visit `/posts` twice. In the Rails log:

- First visit: `Read fragment ... (miss)` then `Write fragment ...`
- Second visit: `Read fragment ... (hit)`

When you update a post, its cache key changes (`cache_version`), the next view miss re-renders just that fragment.

For the cache backend in production, see Solid Cache config in this chapter's README.
