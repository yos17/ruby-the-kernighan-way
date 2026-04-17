# tiny_renderer.rb — ERB-based template renderer
# Usage: ruby tiny_renderer.rb (demo)

require "erb"

# Renderer — fills `.erb` templates with values and returns the
# resulting string. ERB is Ruby's built-in templating engine, the
# same one that powers Rails views. `<%= expr %>` interpolates a
# value; `<% code %>` runs code without printing.
class Renderer
  def initialize(template_dir = ".")
    @template_dir = template_dir
    # Compiled ERB templates are expensive to build; caching them
    # by name turns render-time into a simple hash lookup.
    @cache = {}
  end

  # Render one template after filling a binding with the supplied locals.
  #
  # A `binding` is a snapshot of the current scope — local
  # variables, self, the works. ERB runs the template against a
  # binding, so whatever variables exist there become available
  # inside `<%= %>` tags. We create a fresh binding, poke each
  # local the caller passed into it, and hand it to ERB.
  def render(name, locals = {})
    # `||=` caches the compiled template on first access.
    template = @cache[name] ||= ERB.new(File.read(File.join(@template_dir, "#{name}.erb")))
    bind = binding
    # `local_variable_set(:name, value)` injects each key/value
    # pair into our binding, so the template can refer to them
    # as if they were ordinary locals.
    locals.each { |k, v| bind.local_variable_set(k, v) }
    template.result(bind)
  end
end

if __FILE__ == $PROGRAM_NAME
  require "tmpdir"
  dir = Dir.mktmpdir
  File.write(File.join(dir, "greet.erb"), <<~ERB)
    <h1>Hello, <%= name %>!</h1>
    <ul>
    <% items.each do |item| %>
      <li><%= item %></li>
    <% end %>
    </ul>
  ERB

  r = Renderer.new(dir)
  puts r.render("greet", name: "Yosia", items: ["one", "two", "three"])
end
