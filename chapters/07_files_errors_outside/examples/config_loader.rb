# config_loader.rb — layered config (defaults < json < env)
# Usage: ruby config_loader.rb [config.json]

require "json"

class ConfigError < StandardError; end

class Config
  DEFAULTS = {
    host: "localhost",
    port: 8080,
    log_level: "info",
    database_url: "sqlite::memory:"
  }.freeze

  def self.load(path = nil)
    config = DEFAULTS.dup
    config.merge!(load_file(path)) if path && File.exist?(path)
    config.merge!(load_env)
    new(config)
  end

  def self.load_file(path)
    JSON.parse(File.read(path), symbolize_names: true)
  rescue JSON::ParserError => e
    raise ConfigError, "invalid JSON in #{path}: #{e.message}"
  end

  def self.load_env
    DEFAULTS.keys.each_with_object({}) do |key, h|
      env_value = ENV["APP_#{key.upcase}"]
      h[key] = env_value if env_value
    end
  end

  attr_reader :data

  def initialize(data) = @data = data.freeze
  def [](key) = @data.fetch(key)
  def to_s   = @data.map { |k, v| "  #{k}: #{v}" }.join("\n")
end

if __FILE__ == $PROGRAM_NAME
  config = Config.load(ARGV[0])
  puts "config:"
  puts config
end
