# Solution to Exercise 3
require "json"

class ConfigError < StandardError; end
class MissingKey < ConfigError
  def initialize(key) = super("missing required config key: #{key}")
end

class Config
  DEFAULTS = { host: nil, port: nil, log_level: "info" }.freeze

  def self.load(path = nil, required: [])
    config = DEFAULTS.dup
    config.merge!(JSON.parse(File.read(path), symbolize_names: true)) if path && File.exist?(path)
    DEFAULTS.keys.each { |k| (v = ENV["APP_#{k.upcase}"]) && config[k] = v }

    required.each do |key|
      raise MissingKey.new(key) if config[key].nil? || config[key].to_s.empty?
    end

    new(config)
  end

  attr_reader :data

  def initialize(data) = @data = data.freeze
  def [](key) = @data.fetch(key)
end

if __FILE__ == $PROGRAM_NAME
  begin
    Config.load(required: [:host])
  rescue MissingKey => e
    puts "caught: #{e.message}"
  end

  ENV["APP_HOST"] = "example.com"
  c = Config.load(required: [:host])
  puts "host: #{c[:host]}"
end
