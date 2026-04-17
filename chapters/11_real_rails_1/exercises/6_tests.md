# Exercise 6 — Test PostsController#create

Edit `test/controllers/posts_controller_test.rb`:

```ruby
require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = Author.create!(name: "Test", email: "t@example.com")
    @valid_params   = { post: { title: "First Post", body: "Hello", author_id: @author.id } }
    @invalid_params = { post: { title: "ab", body: "" } }
  end

  test "creates a post with valid params" do
    assert_difference("Post.count", 1) do
      post posts_url, params: @valid_params
    end
    assert_redirected_to post_url(Post.last)
  end

  test "renders new with invalid params and 422" do
    assert_no_difference("Post.count") do
      post posts_url, params: @invalid_params
    end
    assert_response :unprocessable_entity
  end
end
```

Run:

```bash
bin/rails test test/controllers/posts_controller_test.rb
```

The bundled Minitest runner gives you `assert_difference`, `assert_redirected_to`, `assert_response`, and the `setup`/`teardown` blocks. `ActionDispatch::IntegrationTest` exercises the whole stack — routing, controller, view rendering — so these are *integration* tests, the most useful kind for controllers.
