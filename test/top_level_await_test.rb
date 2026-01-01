# frozen_string_literal: true

require_relative "test_helper"

class TopLevelAwaitTest < Minitest::Test
  def setup
    @mock = MockHTTPSandbox.new
    @sandbox = @mock.create_sandbox
  end

  # ============================================================================
  # Basic Top-Level Await Tests (no async IIFE required)
  # ============================================================================

  def test_top_level_await_with_promise_resolve
    result = @sandbox.eval(<<~JS)
      await Promise.resolve(42);
    JS

    assert_equal 42, result.value
  end

  def test_top_level_await_with_fetch
    result = @sandbox.eval(<<~JS)
      const response = await fetch('https://api.example.com/data');
      response.body;
    JS

    assert_equal '{"message": "success"}', result.value
    assert_equal 1, @mock.requests.length
    assert_equal "GET", @mock.requests[0][:method]
  end

  def test_top_level_await_with_json_parsing
    @mock.queue_response({
                           status: 200,
                           statusText: "OK",
                           body: '{"name": "Alice", "age": 30}',
                           headers: { "content-type" => "application/json" }
                         })

    result = @sandbox.eval(<<~JS)
      const response = await fetch('https://api.example.com/user');
      const data = await response.json();
      data.name + " is " + data.age;
    JS

    assert_equal "Alice is 30", result.value
  end

  def test_top_level_await_multiple_fetches
    @mock.queue_response({
                           status: 200,
                           statusText: "OK",
                           body: '{"id": 1}',
                           headers: {}
                         })
    @mock.queue_response({
                           status: 200,
                           statusText: "OK",
                           body: '{"id": 2}',
                           headers: {}
                         })

    result = @sandbox.eval(<<~JS)
      const r1 = await fetch('https://api.example.com/first');
      const r2 = await fetch('https://api.example.com/second');
      const d1 = await r1.json();
      const d2 = await r2.json();
      d1.id + d2.id;
    JS

    assert_equal 3, result.value
    assert_equal 2, @mock.requests.length
  end

  def test_top_level_await_with_response_status
    @mock.queue_response({
                           status: 201,
                           statusText: "Created",
                           body: "{}",
                           headers: {}
                         })

    result = @sandbox.eval(<<~JS)
      const response = await fetch('https://api.example.com/create', { method: 'POST' });
      response.status;
    JS

    assert_equal 201, result.value
  end

  def test_top_level_await_with_text_method
    @mock.queue_response({
                           status: 200,
                           statusText: "OK",
                           body: "Hello, World!",
                           headers: { "content-type" => "text/plain" }
                         })

    result = @sandbox.eval(<<~JS)
      const response = await fetch('https://api.example.com/greeting');
      await response.text();
    JS

    assert_equal "Hello, World!", result.value
  end

  def test_top_level_await_with_headers
    result = @sandbox.eval(<<~JS)
      const response = await fetch('https://api.example.com/data', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer token123'
        },
        body: JSON.stringify({ key: 'value' })
      });
      response.status;
    JS

    assert_equal 200, result.value
    assert_equal "POST", @mock.requests[0][:method]
    assert_equal '{"key":"value"}', @mock.requests[0][:body]
    assert_equal "application/json", @mock.requests[0][:headers]["Content-Type"]
    assert_equal "Bearer token123", @mock.requests[0][:headers]["Authorization"]
  end

  def test_top_level_await_with_error_handling
    @mock.queue_response({
                           status: 404,
                           statusText: "Not Found",
                           body: '{"error": "Resource not found"}',
                           headers: {}
                         })

    result = @sandbox.eval(<<~JS)
      const response = await fetch('https://api.example.com/missing');
      response.ok ? "found" : "not found";
    JS

    assert_equal "not found", result.value
  end

  # ============================================================================
  # Comparison: Top-Level Await vs IIFE (both should work)
  # ============================================================================

  def test_iife_still_works
    result = @sandbox.eval(<<~JS)
      (async () => {
        const response = await fetch('https://api.example.com/data');
        return response.body;
      })()
    JS

    assert_equal '{"message": "success"}', result.value
  end

  def test_top_level_equivalent_to_iife
    # Using top-level await
    result1 = @sandbox.eval(<<~JS)
      const r1 = await fetch('https://api.example.com/data');
      r1.body;
    JS

    # Reset mock for second test
    @mock2 = MockHTTPSandbox.new
    sandbox2 = @mock2.create_sandbox

    # Using IIFE
    result2 = sandbox2.eval(<<~JS)
      (async () => {
        const r2 = await fetch('https://api.example.com/data');
        return r2.body;
      })()
    JS

    assert_equal result1.value, result2.value
  end

  # ============================================================================
  # Pure Promise Tests (no fetch)
  # ============================================================================

  def test_top_level_await_promise_chain
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      const value = await Promise.resolve(10)
        .then(x => x * 2)
        .then(x => x + 5);
      value;
    JS

    assert_equal 25, result.value
  end

  def test_top_level_await_promise_all
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      const [a, b, c] = await Promise.all([
        Promise.resolve(1),
        Promise.resolve(2),
        Promise.resolve(3)
      ]);
      a + b + c;
    JS

    assert_equal 6, result.value
  end

  def test_top_level_await_with_delay_simulation
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      const delay = (ms, value) => new Promise(resolve => {
        // QuickJS doesn't have setTimeout, so resolve immediately
        resolve(value);
      });

      const result = await delay(100, "delayed value");
      result;
    JS

    assert_equal "delayed value", result.value
  end

  def test_top_level_await_async_function_call
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      async function fetchData() {
        return { name: "test", value: 42 };
      }

      const data = await fetchData();
      data.value;
    JS

    assert_equal 42, result.value
  end

  def test_top_level_await_nested_async
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      async function outer() {
        async function inner() {
          return await Promise.resolve(100);
        }
        return await inner() + 50;
      }

      await outer();
    JS

    assert_equal 150, result.value
  end

  # ============================================================================
  # Edge Cases
  # ============================================================================

  def test_top_level_await_with_variable_declarations
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      let x = 10;
      const y = await Promise.resolve(20);
      var z = 30;
      x + y + z;
    JS

    assert_equal 60, result.value
  end

  def test_top_level_await_last_expression_is_await
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      await Promise.resolve("final value");
    JS

    assert_equal "final value", result.value
  end

  def test_top_level_await_with_object_result
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      await Promise.resolve({ a: 1, b: 2, c: 3 });
    JS

    assert_equal({ "a" => 1, "b" => 2, "c" => 3 }, result.value)
  end

  def test_top_level_await_with_array_result
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      await Promise.resolve([1, 2, 3, 4, 5]);
    JS

    assert_equal [1, 2, 3, 4, 5], result.value
  end

  def test_regular_code_still_works
    sandbox = QuickJS::Sandbox.new

    result = sandbox.eval(<<~JS)
      const sum = (a, b) => a + b;
      sum(10, 20);
    JS

    assert_equal 30, result.value
  end
end
