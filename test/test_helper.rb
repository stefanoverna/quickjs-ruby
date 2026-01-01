# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/quickjs"

# Test helper that creates a sandbox with a mock HTTP handler
class MockHTTPSandbox
  attr_reader :requests

  def initialize
    @requests = []
    @responses = []
  end

  def queue_response(response)
    @responses << response
  end

  def default_response
    {
      status: 200,
      statusText: "OK",
      body: '{"message": "success"}',
      headers: { "content-type" => "application/json" }
    }
  end

  def create_sandbox
    sandbox = QuickJS::Sandbox.new

    # Inject our mock callback directly (bypassing HTTPConfig/HTTPExecutor)
    # This is a test-only pattern - we set the callback and clear
    # the http_executor so reset_http_executor won't overwrite it
    requests = @requests
    responses = @responses
    default = method(:default_response)

    sandbox.instance_variable_get(:@native_sandbox).http_callback = lambda do |method, url, body, headers|
      requests << { method: method, url: url, body: body, headers: headers }
      responses.shift || default.call
    end

    # Ensure reset_http_executor won't run (no @http_executor set)
    # The sandbox was created without http: option, so @http_executor is nil

    sandbox
  end
end
