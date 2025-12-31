#!/usr/bin/env ruby
# frozen_string_literal: true

require "quickjs"
require "minitest/autorun"
require "json"

class TestHTTPExecutor < Minitest::Test
  def test_http_config_initialization
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://api.example.com/*"],
      max_requests: 5
    )

    assert_equal 5, config.max_requests
    assert config.allowed?("https://api.example.com/data")
    refute config.allowed?("https://other.com/data")
  end

  # NOTE: These tests validate HTTP infrastructure without making actual HTTP calls
  # Full HTTP integration tests with real requests would require a test server

  def test_http_executor_blocked_url
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://allowed.com/**"]
    )

    executor = QuickJS::HTTPExecutor.new(config)

    error = assert_raises(QuickJS::HTTPBlockedError) do
      executor.execute("GET", "https://blocked.com/data")
    end

    assert_match(/not in allowlist/, error.message)
  end

  def test_http_executor_initializes_properly
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://api.example.com/**"],
      max_requests: 5
    )

    executor = QuickJS::HTTPExecutor.new(config)

    assert_equal 0, executor.http_requests.size
  end

  def test_http_executor_method_validation
    config = QuickJS::HTTPConfig.new(
      allowlist: ["http://localhost:8765/**"],
      allowed_methods: %w[GET POST]
    )

    executor = QuickJS::HTTPExecutor.new(config)

    error = assert_raises(QuickJS::HTTPBlockedError) do
      executor.execute("DELETE", "http://localhost:8765/get")
    end

    assert_match(/not allowed/, error.message)
  end

  def test_http_config_limits
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://api.example.com/**"],
      max_response_size: 1000,
      max_requests: 10,
      request_timeout: 5000
    )

    assert_equal 1000, config.max_response_size
    assert_equal 10, config.max_requests
    assert_equal 5000, config.request_timeout
  end

  def test_http_request_object
    request = QuickJS::HTTPRequest.new(
      method: "GET",
      url: "https://api.example.com/data",
      status: 200,
      duration_ms: 150,
      request_size: 256,
      response_size: 1024
    )

    assert_equal "GET", request.method
    assert_equal "https://api.example.com/data", request.url
    assert_equal 200, request.status
    assert_equal 150, request.duration_ms

    hash = request.to_h

    assert_equal "GET", hash[:method]
    assert_equal 200, hash[:status]
  end
end

puts "Running HTTP executor tests..."
