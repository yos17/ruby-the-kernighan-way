# plugins.rb — a tiny plugin system
# Usage: ruby plugins.rb (demo, loads from examples/plugins/)

class Host
  def initialize
    @plugins = []
  end

  def install(plugin_module)
    extend(plugin_module)
    @plugins << plugin_module
    self
  end

  def list_plugins = @plugins.map(&:name)
end

if __FILE__ == $PROGRAM_NAME
  Dir[File.join(__dir__, "plugins", "*.rb")].each { |f| require f }

  host = Host.new
  host.install(Greeter).install(Counter)

  puts host.list_plugins
  puts host.greet("Yosia")
  puts host.tick
  puts host.tick
end
