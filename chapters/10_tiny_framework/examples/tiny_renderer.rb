# tiny_renderer.rb — ERB-based template renderer
# Usage: ruby tiny_renderer.rb (demo)

require "erb"

class Renderer
  def initialize(template_dir = ".")
    @template_dir = template_dir
    @cache = {}
  end

  def render(name, locals = {})
    template = @cache[name] ||= ERB.new(File.read(File.join(@template_dir, "#{name}.erb")))
    bind = binding
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
