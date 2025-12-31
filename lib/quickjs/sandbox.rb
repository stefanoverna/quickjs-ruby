# frozen_string_literal: true

module QuickJS
  # Sandbox provides a secure JavaScript execution environment.
  #
  # This class wraps the native C-based sandbox and provides a simpler
  # interface for HTTP configuration.
  class Sandbox
    # Create a new JavaScript sandbox
    #
    # @param memory_limit [Integer] Memory limit in bytes (default: 1,000,000 = 1MB)
    # @param timeout_ms [Integer] Execution timeout in milliseconds (default: 5,000)
    # @param console_log_max_size [Integer] Console output limit in bytes (default: 10,000)
    # @param http [Hash, nil] HTTP configuration options (enables fetch() in JavaScript)
    #
    # @option http [Array<String>] :allowlist URL patterns to allow (e.g., ['https://api.github.com/**'])
    # @option http [Array<String>] :denylist URL patterns to block (allows all others)
    # @option http [Integer] :max_requests Maximum requests per eval (default: 10)
    # @option http [Integer] :request_timeout Request timeout in ms (default: 5000)
    # @option http [Integer] :max_request_size Maximum request body size (default: 1MB)
    # @option http [Integer] :max_response_size Maximum response size (default: 1MB)
    # @option http [Array<String>] :allowed_methods HTTP methods allowed (default: GET, POST, PUT, DELETE, PATCH, HEAD)
    # @option http [Array<Integer>] :allowed_ports Allowed ports (default: [80, 443])
    # @option http [Boolean] :block_private_ips Block private/local IPs (default: true)
    #
    # @example Basic usage
    #   sandbox = QuickJS::Sandbox.new
    #   result = sandbox.eval("2 + 2")
    #   result.value  # => 4
    #
    # @example With HTTP enabled (allowlist mode)
    #   sandbox = QuickJS::Sandbox.new(
    #     http: {
    #       allowlist: ['https://api.github.com/**'],
    #       max_requests: 5
    #     }
    #   )
    #   result = sandbox.eval("fetch('https://api.github.com/users/octocat').body")
    #
    # @example With HTTP enabled (denylist mode - allow all except blocked)
    #   sandbox = QuickJS::Sandbox.new(
    #     http: {
    #       denylist: ['https://evil.com/**', 'https://*.malware.net/**']
    #     }
    #   )
    #   result = sandbox.eval("fetch('https://safe-api.com/data').body")
    #
    def initialize(memory_limit: 1_000_000, timeout_ms: 5000, console_log_max_size: 10_000, http: nil)
      # QuickJS (full version) requires more memory than MicroQuickJS. The minimum
      # practical value is around 100KB, but we recommend at least 1MB for most use cases.
      raise ArgumentError, "memory_limit cannot be less than 100000 bytes (got #{memory_limit})" if memory_limit < 100_000

      @native_sandbox = NativeSandbox.new(
        memory_limit: memory_limit,
        timeout_ms: timeout_ms,
        console_log_max_size: console_log_max_size
      )

      @http_config = nil
      @http_executor = nil

      setup_http(http) if http
    end

    # Evaluate JavaScript code in the sandbox
    #
    # @param code [String] JavaScript code to execute
    # @return [Result] Result object with value, console_output, etc.
    # @raise [SyntaxError] Invalid JavaScript syntax
    # @raise [JavascriptError] JavaScript runtime error
    # @raise [MemoryLimitError] Memory limit exceeded
    # @raise [TimeoutError] Execution timeout
    # @raise [HTTPError] HTTP security violation (when HTTP is enabled)
    def eval(code)
      reset_http_executor if @http_executor
      @native_sandbox.eval(code)
    end

    # Set a global variable in the sandbox from Ruby
    #
    # @param name [String] Variable name
    # @param value [Object] Ruby value (nil, boolean, number, string, array, or hash)
    def set_variable(name, value)
      @native_sandbox.set_variable(name, value)
    end

    private

    def setup_http(http_options)
      @http_config = HTTPConfig.new(http_options)
      @http_executor = HTTPExecutor.new(@http_config)

      @native_sandbox.http_callback = lambda do |method, url, body, headers|
        @http_executor.execute(method, url, body: body, headers: headers)
      end
    end

    def reset_http_executor
      # Create a fresh executor for each eval to reset request counts
      @http_executor = HTTPExecutor.new(@http_config)

      @native_sandbox.http_callback = lambda do |method, url, body, headers|
        @http_executor.execute(method, url, body: body, headers: headers)
      end
    end
  end
end
