# tiny_http_client.rb — minimal HTTP client for JSON APIs
# Usage: ruby tiny_http_client.rb [url]
# Default URL is https://api.github.com/users/octocat (requires network)

require "net/http"
require "uri"
require "json"

class HttpClient
  class HttpError < StandardError
    attr_reader :status

    # Store the HTTP status code alongside the message body.
    def initialize(status, message)
      @status = status
      super(message)
    end
  end

  # Remember the base URL so later requests only need a path.
  def initialize(base_url) = @base_url = base_url

  # Perform one GET request, retrying transient failures and parsing JSON on success.
  def get(path)
    uri = URI.join(@base_url, path)
    response = with_retry { Net::HTTP.get_response(uri) }
    raise HttpError.new(response.code.to_i, response.body) unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body, symbolize_names: true)
  end

  private

  # Retry a transient network block a few times before giving up.
  def with_retry(max: 3)
    attempts = 0
    begin
      attempts += 1
      yield
    rescue Net::OpenTimeout, Errno::ECONNRESET => e
      retry if attempts < max
      raise
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  url = ARGV[0] || "https://api.github.com/users/octocat"
  uri = URI(url)
  base = "#{uri.scheme}://#{uri.host}"
  path = uri.request_uri

  client = HttpClient.new(base)
  begin
    data = client.get(path)
    puts data.inspect[0..200]
  rescue HttpClient::HttpError => e
    puts "HTTP #{e.status}: #{e.message[0..100]}"
  rescue SocketError => e
    puts "network error: #{e.message}"
  end
end
