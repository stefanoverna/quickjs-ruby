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

class FetchTest < Minitest::Test
  def setup
    @mock = MockHTTPSandbox.new
    @sandbox = @mock.create_sandbox
  end

  # ============================================================================
  # Basic Request Tests
  # ============================================================================

  def test_basic_get_request
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        return response.body;
      })()
    JS

    assert_equal '{"message": "success"}', result.value
    assert_equal 1, @mock.requests.length
    assert_equal "GET", @mock.requests[0][:method]
    assert_equal "https://api.example.com/data", @mock.requests[0][:url]
  end

  def test_post_request
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users', { method: 'POST' });
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal "POST", @mock.requests[0][:method]
  end

  def test_put_request
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users/1', { method: 'PUT' });
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal "PUT", @mock.requests[0][:method]
  end

  def test_delete_request
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users/1', { method: 'DELETE' });
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal "DELETE", @mock.requests[0][:method]
  end

  def test_patch_request
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users/1', { method: 'PATCH' });
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal "PATCH", @mock.requests[0][:method]
  end

  def test_head_request
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data', { method: 'HEAD' });
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal "HEAD", @mock.requests[0][:method]
  end

  def test_options_request
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data', { method: 'OPTIONS' });
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal "OPTIONS", @mock.requests[0][:method]
  end

  # ============================================================================
  # Request Body Tests
  # ============================================================================

  def test_request_with_string_body
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users', {
          method: 'POST',
          body: 'plain text body'
        });
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal "plain text body", @mock.requests[0][:body]
  end

  def test_request_with_json_body
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users', {
          method: 'POST',
          body: JSON.stringify({name: 'John', age: 30})
        });
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal '{"name":"John","age":30}', @mock.requests[0][:body]
  end

  def test_request_without_body
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_nil @mock.requests[0][:body]
  end

  # ============================================================================
  # Response Property Tests
  # ============================================================================

  def test_response_status
    @mock.queue_response(status: 201, statusText: "Created", body: "", headers: {})

    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users');
        return response.status;
      })()
    JS

    assert_equal 201, result.value
  end

  def test_response_status_text
    @mock.queue_response(status: 404, statusText: "Not Found", body: "", headers: {})

    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users');
        return response.statusText;
      })()
    JS

    assert_equal "Not Found", result.value
  end

  def test_response_ok_true_for_200
    @mock.queue_response(status: 200, statusText: "OK", body: "", headers: {})

    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        return response.ok;
      })()
    JS

    assert result.value
  end

  def test_response_ok_false_for_404
    @mock.queue_response(status: 404, statusText: "Not Found", body: "", headers: {})

    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        return response.ok;
      })()
    JS

    refute result.value
  end

  def test_response_body
    @mock.queue_response(status: 200, statusText: "OK", body: "Hello World", headers: {})

    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        return response.body;
      })()
    JS

    assert_equal "Hello World", result.value
  end

  def test_response_all_properties
    @mock.queue_response(
      status: 201,
      statusText: "Created",
      body: '{"id": 123}',
      headers: { "content-type" => "application/json" }
    )

    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users');
        return JSON.stringify({
          status: response.status,
          statusText: response.statusText,
          ok: response.ok,
          body: response.body,
          hasHeaders: typeof response.headers === 'object'
        });
      })()
    JS

    data = JSON.parse(result.value)

    assert_equal 201, data["status"]
    assert_equal "Created", data["statusText"]
    assert data["ok"]
    assert_equal '{"id": 123}', data["body"]
    assert data["hasHeaders"]
  end

  # ============================================================================
  # JSON Parsing Tests
  # ============================================================================

  def test_parse_json_response
    @mock.queue_response(
      status: 200,
      statusText: "OK",
      body: '{"name": "John", "age": 30}',
      headers: { "content-type" => "application/json" }
    )

    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/user');
        var data = await response.json();
        return data.name;
      })()
    JS

    assert_equal "John", result.value
  end

  def test_parse_json_array_response
    @mock.queue_response(
      status: 200,
      statusText: "OK",
      body: '[{"id": 1}, {"id": 2}, {"id": 3}]',
      headers: { "content-type" => "application/json" }
    )

    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/users');
        var data = await response.json();
        return data.length;
      })()
    JS

    assert_equal 3, result.value
  end

  # ============================================================================
  # URL Tests
  # ============================================================================

  def test_url_with_query_params
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/search?q=test&limit=10');
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal "https://api.example.com/search?q=test&limit=10", @mock.requests[0][:url]
  end

  def test_url_with_path_segments
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/v1/users/123/posts');
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal "https://api.example.com/v1/users/123/posts", @mock.requests[0][:url]
  end

  # ============================================================================
  # Error Handling Tests
  # ============================================================================

  def test_error_missing_url
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("fetch()")
    end

    assert_match(/requires at least 1 argument/i, error.message)
  end

  def test_error_no_http_callback
    sandbox = QuickJS::Sandbox.new
    # No http: option set

    error = assert_raises(QuickJS::JavascriptError) do
      sandbox.eval("fetch('https://example.com')")
    end

    assert_match(/not enabled|callback not configured/i, error.message)
  end

  # ============================================================================
  # Multiple Request Tests
  # ============================================================================

  def test_multiple_sequential_requests
    @mock.queue_response(status: 200, statusText: "OK", body: "first", headers: {})
    @mock.queue_response(status: 201, statusText: "Created", body: "second", headers: {})
    @mock.queue_response(status: 202, statusText: "Accepted", body: "third", headers: {})

    result = @sandbox.eval(<<~JS)
      (async () => {
        var r1 = await fetch('https://api.example.com/1');
        var r2 = await fetch('https://api.example.com/2');
        var r3 = await fetch('https://api.example.com/3');
        return r1.body + ',' + r2.body + ',' + r3.body;
      })()
    JS

    assert_equal "first,second,third", result.value
    assert_equal 3, @mock.requests.length
  end

  def test_request_in_function
    result = @sandbox.eval(<<~JS)
      (async () => {
        async function getData(url) {
          var response = await fetch(url);
          return response.body;
        }
        return await getData('https://api.example.com/data');
      })()
    JS

    assert_equal '{"message": "success"}', result.value
  end

  def test_request_in_loop
    @mock.queue_response(status: 200, statusText: "OK", body: "a", headers: {})
    @mock.queue_response(status: 200, statusText: "OK", body: "b", headers: {})
    @mock.queue_response(status: 200, statusText: "OK", body: "c", headers: {})

    result = @sandbox.eval(<<~JS)
      (async () => {
        var results = [];
        for (var i = 0; i < 3; i++) {
          var response = await fetch('https://api.example.com/item/' + i);
          results.push(response.body);
        }
        return results.join(',');
      })()
    JS

    assert_equal "a,b,c", result.value
    assert_equal 3, @mock.requests.length
  end

  # ============================================================================
  # Integration with Console Tests
  # ============================================================================

  def test_fetch_with_console_log
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        console.log('Status:', response.status);
        return response.body;
      })()
    JS

    assert_equal '{"message": "success"}', result.value
    assert_includes result.console_output, "Status:"
    assert_includes result.console_output, "200"
  end

  # ============================================================================
  # Unicode Tests
  # ============================================================================

  def test_unicode_in_response_body
    @mock.queue_response(
      status: 200,
      statusText: "OK",
      body: '{"message": "こんにちは世界"}',
      headers: {}
    )

    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        var data = await response.json();
        return data.message;
      })()
    JS

    assert_equal "こんにちは世界", result.value
  end

  # ============================================================================
  # Async/Await and Promise Tests
  # ============================================================================

  def test_fetch_returns_promise
    result = @sandbox.eval(<<~JS)
      fetch('https://api.example.com/data') instanceof Promise
    JS
    assert result.value
  end

  def test_fetch_with_then_chain
    result = @sandbox.eval(<<~JS)
      fetch('https://api.example.com/data')
        .then(response => response.json())
        .then(data => data.message)
    JS
    assert_equal "success", result.value
  end

  def test_fetch_error_caught_with_catch
    result = @sandbox.eval(<<~JS)
      fetch()
        .catch(e => e.message)
    JS
    assert_match(/requires at least 1 argument/i, result.value)
  end
end

# ============================================================================
# High-level API Tests (using the new simplified http: option)
# ============================================================================

class FetchHighLevelAPITest < Minitest::Test
  def test_sandbox_with_http_option_enables_fetch
    sandbox = QuickJS::Sandbox.new(
      http: {
        allowlist: ["https://example.com/**"],
        block_private_ips: false
      }
    )

    # We can't actually make HTTP requests in tests, but we can verify
    # that fetch is enabled and tries to make a request
    error = assert_raises(QuickJS::HTTPBlockedError) do
      sandbox.eval("fetch('https://blocked.com/data')")
    end

    assert_match(/not in allowlist/i, error.message)
  end

  def test_sandbox_without_http_option_disables_fetch
    sandbox = QuickJS::Sandbox.new

    error = assert_raises(QuickJS::JavascriptError) do
      sandbox.eval("fetch('https://example.com')")
    end

    assert_match(/not enabled|callback not configured/i, error.message)
  end

  def test_allowlist_blocks_non_allowed_urls
    sandbox = QuickJS::Sandbox.new(
      http: {
        allowlist: ["https://api.github.com/**"],
        block_private_ips: false
      }
    )

    error = assert_raises(QuickJS::HTTPBlockedError) do
      sandbox.eval("fetch('https://evil.com/steal')")
    end

    assert_match(/not in allowlist/i, error.message)
  end

  def test_denylist_blocks_denied_urls
    sandbox = QuickJS::Sandbox.new(
      http: {
        denylist: ["https://evil.com/**", "https://*.malware.net/**"],
        block_private_ips: false
      }
    )

    error = assert_raises(QuickJS::HTTPBlockedError) do
      sandbox.eval("fetch('https://evil.com/steal')")
    end

    assert_match(/matches denylist/i, error.message)
  end

  def test_denylist_with_subdomain_wildcard
    sandbox = QuickJS::Sandbox.new(
      http: {
        denylist: ["https://*.evil.com/**"],
        block_private_ips: false
      }
    )

    # Subdomains should be blocked
    error = assert_raises(QuickJS::HTTPBlockedError) do
      sandbox.eval("fetch('https://api.evil.com/data')")
    end
    assert_match(/matches denylist/i, error.message)

    # Root domain without subdomain is NOT blocked (pattern requires subdomain)
    # This would make an actual HTTP request in real tests
  end

  def test_mquickjs_eval_with_http_option
    # Test that the convenience method also accepts http: option
    error = assert_raises(QuickJS::HTTPBlockedError) do
      QuickJS.eval(
        "fetch('https://blocked.com/data')",
        http: { allowlist: ["https://allowed.com/**"] }
      )
    end

    assert_match(/not in allowlist/i, error.message)
  end

  def test_denylist_with_protocol_wildcard_and_subdomain
    sandbox = QuickJS::Sandbox.new(
      http: {
        denylist: ["**://*.datocms.com/**"],
        block_private_ips: false
      }
    )

    # Should block https://site-api.datocms.com/test
    error = assert_raises(QuickJS::HTTPBlockedError) do
      sandbox.eval("fetch('https://site-api.datocms.com/test')")
    end
    assert_match(/matches denylist/i, error.message)

    # Should also block http variant
    error = assert_raises(QuickJS::HTTPBlockedError) do
      sandbox.eval("fetch('http://site-api.datocms.com/test')")
    end
    assert_match(/matches denylist/i, error.message)

    # Should also block other subdomains
    error = assert_raises(QuickJS::HTTPBlockedError) do
      sandbox.eval("fetch('https://api.datocms.com/foo')")
    end
    assert_match(/matches denylist/i, error.message)
  end

  # Tests for console output in HTTP exceptions

  def test_http_blocked_error_includes_console_output
    sandbox = QuickJS::Sandbox.new(
      http: { allowlist: ["https://allowed.example.com/**"] }
    )
    error = assert_raises(QuickJS::HTTPBlockedError) do
      sandbox.eval("console.log('before fetch'); console.log('fetching...'); fetch('https://blocked.example.com/api')")
    end
    assert_match(/not in allowlist/i, error.message)
    assert_equal "before fetch\nfetching...\n", error.console_output
    refute_predicate error, :console_truncated?
  end

  def test_http_blocked_error_empty_console_output
    sandbox = QuickJS::Sandbox.new(
      http: { allowlist: ["https://allowed.example.com/**"] }
    )
    error = assert_raises(QuickJS::HTTPBlockedError) do
      sandbox.eval("fetch('https://blocked.example.com/api')")
    end
    assert_match(/not in allowlist/i, error.message)
    assert_equal "", error.console_output
    refute_predicate error, :console_truncated?
  end

  def test_http_blocked_error_with_truncated_console_output
    sandbox = QuickJS::Sandbox.new(
      console_log_max_size: 50,
      http: { allowlist: ["https://allowed.example.com/**"] }
    )
    error = assert_raises(QuickJS::HTTPBlockedError) do
      # Generate more than 50 bytes of console output before fetch
      sandbox.eval("for(var i = 0; i < 10; i++) console.log('line ' + i); fetch('https://blocked.example.com/api')")
    end
    assert_match(/not in allowlist/i, error.message)
    assert_operator error.console_output.bytesize, :<=, 50
    assert_predicate error, :console_truncated?
  end
end
