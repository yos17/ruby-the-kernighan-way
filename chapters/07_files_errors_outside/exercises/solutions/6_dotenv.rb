# Solution to Exercise 6
def load_dotenv(path)
  return unless File.exist?(path)
  File.foreach(path) do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    key, value = line.split("=", 2)
    next unless key && value
    value = value.strip
    # Strip surrounding quotes if present
    value = value[1..-2] if (value.start_with?('"') && value.end_with?('"')) ||
                            (value.start_with?("'") && value.end_with?("'"))
    ENV[key.strip] = value
  end
end

if __FILE__ == $PROGRAM_NAME
  require "tempfile"
  Tempfile.create("dotenv") do |f|
    f.write(<<~ENV)
      # comment
      DB_HOST=localhost
      DB_PORT=5432

      API_KEY="secret value"
    ENV
    f.flush
    load_dotenv(f.path)
  end

  puts "DB_HOST=#{ENV['DB_HOST']}"
  puts "DB_PORT=#{ENV['DB_PORT']}"
  puts "API_KEY=#{ENV['API_KEY']}"
end
