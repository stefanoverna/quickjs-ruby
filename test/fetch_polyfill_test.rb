# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/quickjs"

class FetchPolyfillTest < Minitest::Test
  def setup
    @sandbox = QuickJS::Sandbox.new
  end

  # ============================================================================
  # Headers Class Tests
  # ============================================================================

  def test_headers_constructor_empty
    result = @sandbox.eval(<<~JS)
      var headers = new Headers();
      headers.get('Content-Type')
    JS
    assert_nil result.value
  end

  def test_headers_constructor_with_object
    result = @sandbox.eval(<<~JS)
      var headers = new Headers({ 'Content-Type': 'application/json', 'Accept': 'text/plain' });
      headers.get('content-type')
    JS
    assert_equal "application/json", result.value
  end

  def test_headers_set_and_get
    result = @sandbox.eval(<<~JS)
      var headers = new Headers();
      headers.set('X-Custom', 'value');
      headers.get('x-custom')
    JS
    assert_equal "value", result.value
  end

  def test_headers_append
    result = @sandbox.eval(<<~JS)
      var headers = new Headers();
      headers.append('Accept', 'text/html');
      headers.append('Accept', 'application/json');
      headers.get('Accept')
    JS
    assert_equal "text/html, application/json", result.value
  end

  def test_headers_has
    result = @sandbox.eval(<<~JS)
      var headers = new Headers({ 'Content-Type': 'text/html' });
      JSON.stringify([headers.has('Content-Type'), headers.has('X-Missing')])
    JS
    assert_equal [true, false], JSON.parse(result.value)
  end

  def test_headers_delete
    result = @sandbox.eval(<<~JS)
      var headers = new Headers({ 'Content-Type': 'text/html', 'Accept': 'text/plain' });
      headers.delete('Content-Type');
      JSON.stringify([headers.has('Content-Type'), headers.has('Accept')])
    JS
    assert_equal [false, true], JSON.parse(result.value)
  end

  def test_headers_foreach
    result = @sandbox.eval(<<~JS)
      var headers = new Headers({ 'A': '1', 'B': '2' });
      var collected = [];
      headers.forEach(function(value, name) {
        collected.push(name + ':' + value);
      });
      collected.sort().join(',')
    JS
    assert_equal "a:1,b:2", result.value
  end

  def test_headers_case_insensitive
    result = @sandbox.eval(<<~JS)
      var headers = new Headers();
      headers.set('Content-Type', 'text/html');
      JSON.stringify([
        headers.get('content-type'),
        headers.get('CONTENT-TYPE'),
        headers.get('Content-Type')
      ])
    JS
    values = JSON.parse(result.value)
    assert_equal "text/html", values[0]
    assert_equal "text/html", values[1]
    assert_equal "text/html", values[2]
  end

  # ============================================================================
  # Response Class Tests
  # ============================================================================

  def test_response_constructor_defaults
    result = @sandbox.eval(<<~JS)
      var response = new Response();
      JSON.stringify({
        status: response.status,
        statusText: response.statusText,
        ok: response.ok,
        body: response.body
      })
    JS
    data = JSON.parse(result.value)
    assert_equal 200, data["status"]
    assert_equal "", data["statusText"]
    assert data["ok"]
    assert_equal "", data["body"]
  end

  def test_response_with_body
    result = @sandbox.eval(<<~JS)
      var response = new Response('Hello World');
      response.body
    JS
    assert_equal "Hello World", result.value
  end

  def test_response_with_init_options
    result = @sandbox.eval(<<~JS)
      var response = new Response('Not Found', {
        status: 404,
        statusText: 'Not Found'
      });
      JSON.stringify({
        status: response.status,
        statusText: response.statusText,
        ok: response.ok
      })
    JS
    data = JSON.parse(result.value)
    assert_equal 404, data["status"]
    assert_equal "Not Found", data["statusText"]
    refute data["ok"]
  end

  def test_response_ok_for_various_statuses
    result = @sandbox.eval(<<~JS)
      var results = [];
      [199, 200, 201, 299, 300, 400, 500].forEach(function(status) {
        var response = new Response(null, { status: status });
        results.push({ status: status, ok: response.ok });
      });
      JSON.stringify(results)
    JS
    data = JSON.parse(result.value)
    assert_equal false, data[0]["ok"] # 199
    assert_equal true, data[1]["ok"]  # 200
    assert_equal true, data[2]["ok"]  # 201
    assert_equal true, data[3]["ok"]  # 299
    assert_equal false, data[4]["ok"] # 300
    assert_equal false, data[5]["ok"] # 400
    assert_equal false, data[6]["ok"] # 500
  end

  def test_response_text_method_returns_promise
    result = @sandbox.eval(<<~JS)
      var response = new Response('Hello World');
      response.text()
    JS
    assert_equal "Hello World", result.value
  end

  def test_response_text_with_await
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = new Response('Hello World');
        return await response.text();
      })()
    JS
    assert_equal "Hello World", result.value
  end

  def test_response_json_method_returns_promise
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = new Response('{"name": "John", "age": 30}');
        var data = await response.json();
        return data.name + ' is ' + data.age;
      })()
    JS
    assert_equal "John is 30", result.value
  end

  def test_response_body_used_tracking
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = new Response('test');
        var before = response.bodyUsed;
        await response.text();
        var after = response.bodyUsed;
        return JSON.stringify([before, after]);
      })()
    JS
    assert_equal [false, true], JSON.parse(result.value)
  end

  def test_response_body_cannot_be_used_twice
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval(<<~JS)
        (async () => {
          var response = new Response('test');
          await response.text();
          await response.text();
        })()
      JS
    end
    assert_match(/already been consumed/i, error.message)
  end

  def test_response_clone
    result = @sandbox.eval(<<~JS)
      var original = new Response('test body', { status: 201, statusText: 'Created' });
      var cloned = original.clone();
      JSON.stringify({
        sameBody: original.body === cloned.body,
        clonedStatus: cloned.status,
        clonedStatusText: cloned.statusText,
        originalBodyUsed: original.bodyUsed,
        clonedBodyUsed: cloned.bodyUsed
      })
    JS
    data = JSON.parse(result.value)
    assert data["sameBody"]
    assert_equal 201, data["clonedStatus"]
    assert_equal "Created", data["clonedStatusText"]
    assert_equal false, data["originalBodyUsed"]
    assert_equal false, data["clonedBodyUsed"]
  end

  def test_response_clone_cannot_clone_used_body
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval(<<~JS)
        (async () => {
          var response = new Response('test');
          await response.text();
          response.clone();
        })()
      JS
    end
    assert_match(/cannot clone/i, error.message)
  end

  def test_response_headers
    result = @sandbox.eval(<<~JS)
      var response = new Response('test', {
        headers: { 'Content-Type': 'application/json', 'X-Custom': 'value' }
      });
      response.headers.get('content-type')
    JS
    assert_equal "application/json", result.value
  end

  def test_response_error_static
    result = @sandbox.eval(<<~JS)
      var response = Response.error();
      JSON.stringify({
        status: response.status,
        type: response.type
      })
    JS
    data = JSON.parse(result.value)
    assert_equal 0, data["status"]
    assert_equal "error", data["type"]
  end

  def test_response_redirect_static
    result = @sandbox.eval(<<~JS)
      var response = Response.redirect('https://example.com', 301);
      JSON.stringify({
        status: response.status,
        location: response.headers.get('location')
      })
    JS
    data = JSON.parse(result.value)
    assert_equal 301, data["status"]
    assert_equal "https://example.com", data["location"]
  end

  def test_response_redirect_invalid_status
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("Response.redirect('https://example.com', 200)")
    end
    assert_match(/invalid redirect status/i, error.message)
  end

  def test_response_arraybuffer_method
    result = @sandbox.eval(<<~JS)
      (async () => {
        var response = new Response('ABC');
        var buffer = await response.arrayBuffer();
        var view = new Uint8Array(buffer);
        return JSON.stringify([view[0], view[1], view[2], buffer.byteLength]);
      })()
    JS
    data = JSON.parse(result.value)
    assert_equal 65, data[0] # 'A'
    assert_equal 66, data[1] # 'B'
    assert_equal 67, data[2] # 'C'
    assert_equal 3, data[3]  # length
  end

  # ============================================================================
  # Request Class Tests
  # ============================================================================

  def test_request_constructor_with_url
    result = @sandbox.eval(<<~JS)
      var request = new Request('https://example.com/api');
      JSON.stringify({
        url: request.url,
        method: request.method
      })
    JS
    data = JSON.parse(result.value)
    assert_equal "https://example.com/api", data["url"]
    assert_equal "GET", data["method"]
  end

  def test_request_with_method
    result = @sandbox.eval(<<~JS)
      var request = new Request('https://example.com', { method: 'POST' });
      request.method
    JS
    assert_equal "POST", result.value
  end

  def test_request_method_normalization
    result = @sandbox.eval(<<~JS)
      var methods = ['get', 'post', 'put', 'delete', 'patch', 'head', 'options'];
      var normalized = methods.map(function(m) {
        return new Request('https://example.com', { method: m }).method;
      });
      JSON.stringify(normalized)
    JS
    expected = %w[GET POST PUT DELETE PATCH HEAD OPTIONS]
    assert_equal expected, JSON.parse(result.value)
  end

  def test_request_with_body
    result = @sandbox.eval(<<~JS)
      var request = new Request('https://example.com', {
        method: 'POST',
        body: 'Hello World'
      });
      request.body
    JS
    assert_equal "Hello World", result.value
  end

  def test_request_body_not_allowed_for_get
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval(<<~JS)
        new Request('https://example.com', { method: 'GET', body: 'test' })
      JS
    end
    assert_match(/GET.*cannot have body/i, error.message)
  end

  def test_request_body_not_allowed_for_head
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval(<<~JS)
        new Request('https://example.com', { method: 'HEAD', body: 'test' })
      JS
    end
    assert_match(/HEAD.*cannot have body/i, error.message)
  end

  def test_request_with_headers
    result = @sandbox.eval(<<~JS)
      var request = new Request('https://example.com', {
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer token' }
      });
      JSON.stringify([
        request.headers.get('content-type'),
        request.headers.get('authorization')
      ])
    JS
    data = JSON.parse(result.value)
    assert_equal "application/json", data[0]
    assert_equal "Bearer token", data[1]
  end

  def test_request_clone
    result = @sandbox.eval(<<~JS)
      var original = new Request('https://example.com', {
        method: 'POST',
        body: 'test body',
        headers: { 'X-Custom': 'value' }
      });
      var cloned = original.clone();
      JSON.stringify({
        url: cloned.url,
        method: cloned.method,
        body: cloned.body,
        header: cloned.headers.get('x-custom')
      })
    JS
    data = JSON.parse(result.value)
    assert_equal "https://example.com", data["url"]
    assert_equal "POST", data["method"]
    assert_equal "test body", data["body"]
    assert_equal "value", data["header"]
  end

  def test_request_from_request
    result = @sandbox.eval(<<~JS)
      var original = new Request('https://example.com', { method: 'POST' });
      var copy = new Request(original);
      JSON.stringify({
        url: copy.url,
        method: copy.method
      })
    JS
    data = JSON.parse(result.value)
    assert_equal "https://example.com", data["url"]
    assert_equal "POST", data["method"]
  end

  def test_request_from_request_with_override
    result = @sandbox.eval(<<~JS)
      var original = new Request('https://example.com', { method: 'POST' });
      var modified = new Request(original, { method: 'PUT' });
      JSON.stringify({
        originalMethod: original.method,
        modifiedMethod: modified.method
      })
    JS
    data = JSON.parse(result.value)
    assert_equal "POST", data["originalMethod"]
    assert_equal "PUT", data["modifiedMethod"]
  end

  # ============================================================================
  # Async Fetch Integration Tests
  # ============================================================================

  def test_fetch_returns_promise
    mock = MockHTTPSandbox.new
    sandbox = mock.create_sandbox

    result = sandbox.eval(<<~JS)
      var promise = fetch('https://api.example.com/data');
      promise instanceof Promise
    JS
    assert result.value
  end

  def test_fetch_resolves_to_response
    mock = MockHTTPSandbox.new
    sandbox = mock.create_sandbox

    result = sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        return response instanceof Response;
      })()
    JS
    assert result.value
  end

  def test_fetch_with_await
    mock = MockHTTPSandbox.new
    mock.queue_response(status: 200, statusText: "OK", body: '{"name":"John"}', headers: {})
    sandbox = mock.create_sandbox

    result = sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        var data = await response.json();
        return data.name;
      })()
    JS
    assert_equal "John", result.value
  end

  def test_fetch_with_then
    mock = MockHTTPSandbox.new
    mock.queue_response(status: 200, statusText: "OK", body: '{"value":42}', headers: {})
    sandbox = mock.create_sandbox

    result = sandbox.eval(<<~JS)
      fetch('https://api.example.com/data')
        .then(response => response.json())
        .then(data => data.value)
    JS
    assert_equal 42, result.value
  end

  def test_fetch_response_text_with_await
    mock = MockHTTPSandbox.new
    mock.queue_response(status: 200, statusText: "OK", body: "Hello World", headers: {})
    sandbox = mock.create_sandbox

    result = sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        return await response.text();
      })()
    JS
    assert_equal "Hello World", result.value
  end

  def test_fetch_response_headers
    mock = MockHTTPSandbox.new
    mock.queue_response(
      status: 200,
      statusText: "OK",
      body: "test",
      headers: { "content-type" => "application/json", "x-custom" => "value" }
    )
    sandbox = mock.create_sandbox

    result = sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/data');
        return response.headers.get('content-type');
      })()
    JS
    assert_equal "application/json", result.value
  end

  def test_fetch_with_request_object
    mock = MockHTTPSandbox.new
    sandbox = mock.create_sandbox

    result = sandbox.eval(<<~JS)
      (async () => {
        var request = new Request('https://api.example.com/users', {
          method: 'POST',
          body: '{"name":"John"}'
        });
        var response = await fetch(request);
        return response.status;
      })()
    JS

    assert_equal 200, result.value
    assert_equal 1, mock.requests.length
    assert_equal "POST", mock.requests[0][:method]
    assert_equal "https://api.example.com/users", mock.requests[0][:url]
    assert_equal '{"name":"John"}', mock.requests[0][:body]
  end

  def test_fetch_with_headers_object
    mock = MockHTTPSandbox.new
    sandbox = mock.create_sandbox

    result = sandbox.eval(<<~JS)
      (async () => {
        var headers = new Headers();
        headers.set('Content-Type', 'application/json');
        headers.set('Authorization', 'Bearer token123');
        var response = await fetch('https://api.example.com/data', {
          method: 'GET',
          headers: headers
        });
        return response.status;
      })()
    JS

    assert_equal 200, result.value
  end

  def test_fetch_error_handling_with_catch
    mock = MockHTTPSandbox.new
    sandbox = mock.create_sandbox

    # Test that fetch errors can be caught
    result = sandbox.eval(<<~JS)
      fetch()
        .then(() => 'should not reach')
        .catch(error => error.message)
    JS
    assert_match(/requires at least 1 argument/i, result.value)
  end

  def test_fetch_status_properties
    mock = MockHTTPSandbox.new
    mock.queue_response(status: 404, statusText: "Not Found", body: "", headers: {})
    sandbox = mock.create_sandbox

    result = sandbox.eval(<<~JS)
      (async () => {
        var response = await fetch('https://api.example.com/missing');
        return JSON.stringify({
          status: response.status,
          statusText: response.statusText,
          ok: response.ok
        });
      })()
    JS
    data = JSON.parse(result.value)
    assert_equal 404, data["status"]
    assert_equal "Not Found", data["statusText"]
    assert_equal false, data["ok"]
  end

  # ============================================================================
  # Promise Tests
  # ============================================================================

  def test_promise_resolve
    result = @sandbox.eval("Promise.resolve(42)")
    assert_equal 42, result.value
  end

  def test_promise_chain
    result = @sandbox.eval(<<~JS)
      Promise.resolve(1)
        .then(x => x + 1)
        .then(x => x * 2)
    JS
    assert_equal 4, result.value
  end

  def test_async_await
    result = @sandbox.eval(<<~JS)
      (async () => {
        const a = await Promise.resolve(10);
        const b = await Promise.resolve(20);
        return a + b;
      })()
    JS
    assert_equal 30, result.value
  end

  def test_promise_reject_is_caught
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("Promise.reject(new Error('test error'))")
    end
    assert_match(/test error/i, error.message)
  end
end

# Mock HTTP sandbox helper (copied from fetch_test.rb for standalone execution)
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

    requests = @requests
    responses = @responses
    default = method(:default_response)

    sandbox.instance_variable_get(:@native_sandbox).http_callback = lambda do |method, url, body, headers|
      requests << { method: method, url: url, body: body, headers: headers }
      responses.shift || default.call
    end

    sandbox
  end
end
