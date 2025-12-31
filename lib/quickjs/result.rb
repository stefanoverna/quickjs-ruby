# frozen_string_literal: true

module QuickJS
  # Result of evaluating JavaScript code
  class Result
    attr_reader :value, :console_output, :http_requests

    def initialize(value, console_output, console_truncated, http_requests = [])
      @value = value
      @console_output = console_output
      @console_truncated = console_truncated
      @http_requests = http_requests
    end

    def console_truncated?
      @console_truncated
    end
  end
end
