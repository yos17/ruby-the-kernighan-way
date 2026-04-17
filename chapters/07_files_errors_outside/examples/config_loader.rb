# config_loader.rb — layered config (defaults < json < env)
# Usage: ruby config_loader.rb [config.json]

require "json"

# Custom error class. Subclassing StandardError is the Ruby
# convention — it lets callers rescue ConfigError specifically
# without catching completely unrelated bugs like typos.
class ConfigError < StandardError; end

# Config — loads a layered configuration. Values lower in the
# list win: DEFAULTS < config file < environment variables. That
# "twelve-factor" order is what most production apps use.
class Config
  # `.freeze` makes the hash (and, with `freeze` on its pieces, the
  # values) immutable. That way nobody can accidentally mutate the
  # defaults somewhere else in the program.
  DEFAULTS = {
    host: "localhost",
    port: 8080,
    log_level: "info",
    database_url: "sqlite::memory:"
  }.freeze

  # Merge defaults, optional JSON, and environment variables into one config object.
  def self.load(path = nil)
    config = DEFAULTS.dup
    config.merge!(load_file(path)) if path && File.exist?(path)
    config.merge!(load_env)
    new(config)
  end

  # Parse a JSON config file and wrap parse failures in a clearer domain error.
  def self.load_file(path)
    JSON.parse(File.read(path), symbolize_names: true)
  rescue JSON::ParserError => e
    raise ConfigError, "invalid JSON in #{path}: #{e.message}"
  end

  # Read APP_* environment variables for keys we know about.
  # `each_with_object({})` is a handy fold that builds a result
  # container (`h`) step by step — cleaner than `inject({}) { |h, key| ...; h }`
  # because you never have to remember to return the hash.
  def self.load_env
    DEFAULTS.keys.each_with_object({}) do |key, h|
      env_value = ENV["APP_#{key.upcase}"]
      h[key] = env_value if env_value
    end
  end

  attr_reader :data

  # Freeze the merged hash so callers treat config as read-only.
  def initialize(data) = @data = data.freeze

  # Fetch one config value by key and raise if it is missing.
  # `.fetch` differs from `[]` on a plain hash: missing keys raise
  # KeyError instead of silently returning nil — so typos surface
  # loudly during development instead of hiding as subtle bugs.
  def [](key) = @data.fetch(key)

  # Format the config as readable key/value lines for the demo output.
  def to_s   = @data.map { |k, v| "  #{k}: #{v}" }.join("\n")
end

if __FILE__ == $PROGRAM_NAME
  config = Config.load(ARGV[0])
  puts "config:"
  puts config
end
