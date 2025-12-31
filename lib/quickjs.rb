# frozen_string_literal: true

require_relative "quickjs/version"
require_relative "quickjs/errors"
require_relative "quickjs/result"
require_relative "quickjs/http_config"
require_relative "quickjs/http_executor"
require_relative "quickjs/quickjs_native"
require_relative "quickjs/sandbox"

module QuickJS
  # Convenience method for one-shot evaluation
  #
  # @param code [String] JavaScript code to evaluate
  # @param memory_limit [Integer] Memory limit in bytes (default: 1MB)
  # @param timeout_ms [Integer] Timeout in milliseconds (default: 5000ms)
  # @param http [Hash, nil] HTTP configuration options (enables fetch() in JavaScript)
  # @return [Result] Result object with value, console_output, etc.
  def self.eval(code, memory_limit: 1_000_000, timeout_ms: 5000, http: nil)
    sandbox = Sandbox.new(memory_limit: memory_limit, timeout_ms: timeout_ms, http: http)
    sandbox.eval(code)
  end
end
