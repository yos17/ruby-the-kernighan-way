# plugins.rb — a tiny plugin system
# Usage: ruby plugins.rb (demo, loads from examples/plugins/)

# Host — an object that "accepts" plugins. Each plugin is a
# module of methods; installing one mixes those methods into *this
# specific instance* (not every Host ever created).
class Host
  # Start with no installed plugins.
  def initialize
    @plugins = []
  end

  # `extend(mod)` mixes `mod`'s methods into the singleton class of
  # `self` — only this one object gains those methods. Compare with
  # `include`, which mixes into *every* instance of a class.
  # Returning `self` lets callers chain: host.install(A).install(B).
  def install(plugin_module)
    extend(plugin_module)
    @plugins << plugin_module
    self
  end

  # Show the names of the plugin modules mixed into this host.
  def list_plugins = @plugins.map(&:name)
end

if __FILE__ == $PROGRAM_NAME
  # Auto-discover and load every *.rb file in the plugins/ folder.
  # `Dir[pattern]` returns every path that matches the glob. This is
  # how real plugin systems (Rails initializers, test runners) work.
  Dir[File.join(__dir__, "plugins", "*.rb")].each { |f| require f }

  host = Host.new
  host.install(Greeter).install(Counter)

  puts host.list_plugins
  puts host.greet("Yosia")
  puts host.tick
  puts host.tick
end
