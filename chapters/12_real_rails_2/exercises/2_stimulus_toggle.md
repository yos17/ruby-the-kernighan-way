# Exercise 2 — Stimulus toggle controller

```bash
bin/rails generate stimulus toggle
```

`app/javascript/controllers/toggle_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "trigger"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
    this.triggerTarget.textContent = this.contentTarget.classList.contains("hidden") ? "Show" : "Hide"
  }
}
```

In `app/views/posts/_post.html.erb`:

```erb
<div id="<%= dom_id post %>" data-controller="toggle">
  <h3><%= post.title %></h3>
  <button data-toggle-target="trigger" data-action="click->toggle#toggle">Show</button>
  <div data-toggle-target="content" class="hidden">
    <%= simple_format post.body %>
  </div>
</div>
```

`hidden` is a Tailwind utility (your Rails 11 generator used `--css tailwind`). If you're not using Tailwind, add a `.hidden { display: none }` rule.
