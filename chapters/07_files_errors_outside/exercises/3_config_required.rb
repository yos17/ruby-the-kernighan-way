# Exercise 3 — Config.load with required keys
#
# Config.load(path, required: [:host, :port])
# If any required key is missing or nil after layering, raise MissingKey.

require "json"

class ConfigError < StandardError; end
class MissingKey < ConfigError
  def initialize(key) = super("missing required config key: #{key}")
end

class Config
  DEFAULTS = { host: nil, port: nil, log_level: "info" }.freeze

  # TODO: add a required: keyword
  def self.load(path = nil, required: [])
    config = DEFAULTS.dup
    config.merge!(JSON.parse(File.read(path), symbolize_names: true)) if path && File.exist?(path)
    DEFAULTS.keys.each { |k| (v = ENV["APP_#{k.upcase}"]) && config[k] = v }
    # TODO: check each required key; raise MissingKey for the first missing one
    new(config)
  end

  attr_reader :data

  def initialize(data) = @data = data.freeze
  def [](key) = @data.fetch(key)
end
