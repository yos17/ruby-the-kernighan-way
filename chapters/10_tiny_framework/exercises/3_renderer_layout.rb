# Exercise 3 — Renderer with layouts
#
# render(name, locals, layout: "application") — render `name` first, then
# render `layout` with the inner result available as the `yield` local.
#
# layout template:
#   <!doctype html>
#   <html><body>
#   <%= yield %>
#   </body></html>
#
# inner template (users_index.erb):
#   <h1>Users</h1>
#   <ul>...</ul>

require "erb"

class Renderer
  def initialize(template_dir)
    @template_dir = template_dir
    @cache = {}
  end

  def render(name, locals = {}, layout: nil)
    inner = render_one(name, locals)
    return inner unless layout
    render_one(layout, locals.merge(yield: inner))
  end

  private

  def render_one(name, locals)
    template = @cache[name] ||= ERB.new(File.read(File.join(@template_dir, "#{name}.erb")))
    bind = binding
    locals.each { |k, v| bind.local_variable_set(k, v) }
    template.result(bind)
  end
end

# TODO: write two templates (one inner, one layout) and verify the layout wraps the inner.
