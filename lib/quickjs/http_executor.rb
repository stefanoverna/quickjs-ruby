# frozen_string_literal: true

require "net/http"
require "json"

module QuickJS
  class HTTPExecutor
    def initialize(config)
      @config = config
      @request_count = 0
      @http_requests = []
    end

    attr_reader :http_requests

    # Execute an HTTP request from JavaScript
    # Returns a hash with: {status, statusText, headers, body}
    def execute(method, url, options = {})
      # Validate request count
      if @request_count >= @config.max_requests
        raise HTTPLimitError, "Maximum number of requests (#{@config.max_requests}) exceeded"
      end

      # Validate method
      method = @config.validate_method(method)

      # Validate URL
      @config.validate_url!(url)

      # Parse options
      headers = options[:headers] || {}
      body = options[:body]
      timeout_ms = options[:timeout] || @config.request_timeout

      # Validate request size
      request_size = body ? body.bytesize : 0
      if request_size > @config.max_request_size
        raise HTTPLimitError, "Request body size (#{request_size}) exceeds limit (#{@config.max_request_size})"
      end

      # Track request
      @request_count += 1
      start_time = Time.now

      begin
        # Perform the HTTP request
        response = perform_http_request(method, url, headers, body, timeout_ms)

        # Validate response size
        response_size = response[:body].bytesize
        if response_size > @config.max_response_size
          raise HTTPLimitError, "Response size (#{response_size}) exceeds limit (#{@config.max_response_size})"
        end

        duration_ms = ((Time.now - start_time) * 1000).to_i

        # Log the request
        @http_requests << HTTPRequest.new(
          method: method,
          url: url,
          status: response[:status],
          duration_ms: duration_ms,
          request_size: request_size,
          response_size: response_size
        )

        response
      end
    end

    private

    def perform_http_request(method, url, headers, body, timeout_ms)
      uri = URI.parse(url)

      # Re-validate IP after DNS resolution (prevent DNS rebinding)
      raise HTTPBlockedError, "URL resolves to blocked IP address: #{url}" if @config.blocked_ip?(uri.host)

      # Create HTTP object
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = timeout_ms / 1000.0
      http.read_timeout = timeout_ms / 1000.0

      # Create request
      request = case method
                when "GET"
                  Net::HTTP::Get.new(uri.request_uri)
                when "POST"
                  Net::HTTP::Post.new(uri.request_uri)
                when "PUT"
                  Net::HTTP::Put.new(uri.request_uri)
                when "DELETE"
                  Net::HTTP::Delete.new(uri.request_uri)
                when "PATCH"
                  Net::HTTP::Patch.new(uri.request_uri)
                when "HEAD"
                  Net::HTTP::Head.new(uri.request_uri)
                else
                  raise HTTPBlockedError, "Unsupported HTTP method: #{method}"
                end

      # Set headers
      headers.each { |k, v| request[k] = v }

      # Set body if present
      request.body = body if body

      # Execute request
      response = http.request(request)

      # Build response hash
      response_headers = {}
      response.each_header { |k, v| response_headers[k] = v }

      {
        status: response.code.to_i,
        statusText: response.message,
        headers: response_headers,
        body: response.body || ""
      }
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise HTTPError, "Request timeout: #{e.message}"
    rescue SocketError => e
      raise HTTPError, "Network error: #{e.message}"
    rescue StandardError => e
      raise HTTPError, "HTTP request failed: #{e.message}"
    end
  end
end
