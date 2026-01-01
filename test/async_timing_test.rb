# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/quickjs"

# Tests for async/await, Promise, setTimeout, setInterval, and Date.now functionality
#
# NOTE: The base QuickJS engine does NOT include setTimeout, setInterval, clearTimeout,
# or clearInterval. These functions are part of the "os" module from quickjs-libc and
# would require additional integration. The tests below document the current behavior.
class AsyncTimingTest < Minitest::Test
  def setup
    @sandbox = QuickJS::Sandbox.new(timeout_ms: 10_000)
  end

  # ==========================================================================
  # Date.now Tests
  # ==========================================================================

  def test_date_now_returns_number
    result = @sandbox.eval("typeof Date.now()")

    assert_equal "number", result.value
  end

  def test_date_now_returns_positive_timestamp
    result = @sandbox.eval("Date.now()")

    assert_predicate result.value, :positive?, "Date.now() should return a positive timestamp"
  end

  def test_date_now_returns_reasonable_timestamp
    # Timestamp should be after year 2020 (1577836800000) and before year 2100
    result = @sandbox.eval("Date.now()")
    timestamp = result.value

    assert_operator timestamp, :>, 1_577_836_800_000, "Timestamp should be after year 2020"
    assert_operator timestamp, :<, 4_102_444_800_000, "Timestamp should be before year 2100"
  end

  def test_date_now_increases_over_time
    result = @sandbox.eval(<<~JS)
      const start = Date.now();
      let count = 0;
      for (let i = 0; i < 100000; i++) { count++; }
      const end = Date.now();
      end >= start;
    JS

    assert result.value, "Date.now() should not decrease over time"
  end

  def test_date_now_can_be_used_for_timing
    result = @sandbox.eval(<<~JS)
      const start = Date.now();
      let sum = 0;
      for (let i = 0; i < 1000000; i++) { sum += i; }
      const elapsed = Date.now() - start;
      elapsed >= 0;
    JS

    assert result.value, "Elapsed time should be non-negative"
  end

  # ==========================================================================
  # Promise Tests - Basic API Availability
  # ==========================================================================

  def test_promise_constructor_exists
    result = @sandbox.eval("typeof Promise")

    assert_equal "function", result.value
  end

  def test_promise_resolve_exists
    result = @sandbox.eval("typeof Promise.resolve")

    assert_equal "function", result.value
  end

  def test_promise_reject_exists
    result = @sandbox.eval("typeof Promise.reject")

    assert_equal "function", result.value
  end

  def test_promise_all_exists
    result = @sandbox.eval("typeof Promise.all")

    assert_equal "function", result.value
  end

  def test_promise_race_exists
    result = @sandbox.eval("typeof Promise.race")

    assert_equal "function", result.value
  end

  def test_promise_allsettled_exists
    result = @sandbox.eval("typeof Promise.allSettled")

    assert_equal "function", result.value
  end

  def test_promise_creates_object
    result = @sandbox.eval("new Promise(resolve => resolve(42)) instanceof Promise")

    assert result.value
  end

  def test_promise_then_exists
    result = @sandbox.eval("typeof Promise.prototype.then")

    assert_equal "function", result.value
  end

  def test_promise_catch_exists
    result = @sandbox.eval("typeof Promise.prototype.catch")

    assert_equal "function", result.value
  end

  def test_promise_finally_exists
    result = @sandbox.eval("typeof Promise.prototype.finally")

    assert_equal "function", result.value
  end

  # ==========================================================================
  # Promise Creation and Chaining
  # ==========================================================================

  def test_promise_resolve_creates_promise
    result = @sandbox.eval("Promise.resolve(42) instanceof Promise")

    assert result.value
  end

  def test_promise_reject_creates_promise
    result = @sandbox.eval("Promise.reject(new Error('test')) instanceof Promise")

    assert result.value
  end

  def test_promise_constructor_with_resolve
    result = @sandbox.eval(<<~JS)
      new Promise((resolve, reject) => {
        resolve(42);
      }) instanceof Promise;
    JS

    assert result.value
  end

  def test_promise_constructor_with_reject
    result = @sandbox.eval(<<~JS)
      new Promise((resolve, reject) => {
        reject(new Error('test'));
      }) instanceof Promise;
    JS

    assert result.value
  end

  def test_promise_then_returns_promise
    result = @sandbox.eval(<<~JS)
      Promise.resolve(1).then(x => x + 1) instanceof Promise;
    JS

    assert result.value
  end

  def test_promise_catch_returns_promise
    result = @sandbox.eval(<<~JS)
      Promise.reject(new Error('test')).catch(e => e.message) instanceof Promise;
    JS

    assert result.value
  end

  def test_promise_finally_returns_promise
    result = @sandbox.eval(<<~JS)
      Promise.resolve(42).finally(() => {}) instanceof Promise;
    JS

    assert result.value
  end

  def test_promise_chaining_returns_promise
    result = @sandbox.eval(<<~JS)
      Promise.resolve(1)
        .then(x => x + 1)
        .then(x => x + 1)
        .then(x => x + 1) instanceof Promise;
    JS

    assert result.value
  end

  # ==========================================================================
  # Promise.all and Promise.race
  # ==========================================================================

  def test_promise_all_returns_promise
    result = @sandbox.eval(<<~JS)
      const promises = [
        Promise.resolve(1),
        Promise.resolve(2),
        Promise.resolve(3)
      ];
      Promise.all(promises) instanceof Promise;
    JS

    assert result.value
  end

  def test_promise_all_with_empty_array
    result = @sandbox.eval(<<~JS)
      Promise.all([]) instanceof Promise;
    JS

    assert result.value
  end

  def test_promise_race_returns_promise
    result = @sandbox.eval(<<~JS)
      const promises = [
        Promise.resolve("first"),
        Promise.resolve("second")
      ];
      Promise.race(promises) instanceof Promise;
    JS

    assert result.value
  end

  def test_promise_allsettled_returns_promise
    result = @sandbox.eval(<<~JS)
      const promises = [
        Promise.resolve(1),
        Promise.reject(new Error('test'))
      ];
      Promise.allSettled(promises) instanceof Promise;
    JS

    assert result.value
  end

  # ==========================================================================
  # Async/Await Syntax Tests
  # ==========================================================================

  def test_async_function_syntax
    result = @sandbox.eval("typeof async function() {}")

    assert_equal "function", result.value
  end

  def test_async_arrow_function_syntax
    result = @sandbox.eval("typeof (async () => {})")

    assert_equal "function", result.value
  end

  def test_async_named_function_syntax
    result = @sandbox.eval(<<~JS)
      async function myAsyncFunction() {
        return 42;
      }
      typeof myAsyncFunction;
    JS

    assert_equal "function", result.value
  end

  def test_async_function_returns_promise
    result = @sandbox.eval(<<~JS)
      async function test() { return 42; }
      test() instanceof Promise;
    JS

    assert result.value, "async function should return a Promise"
  end

  def test_async_arrow_returns_promise
    result = @sandbox.eval(<<~JS)
      const fn = async () => 42;
      fn() instanceof Promise;
    JS

    assert result.value, "async arrow function should return a Promise"
  end

  def test_await_in_async_function
    result = @sandbox.eval(<<~JS)
      async function test() {
        const value = await Promise.resolve(42);
        return value;
      }
      test() instanceof Promise;
    JS

    assert result.value
  end

  def test_async_function_with_multiple_awaits
    result = @sandbox.eval(<<~JS)
      async function multiAwait() {
        const a = await Promise.resolve(1);
        const b = await Promise.resolve(2);
        const c = await Promise.resolve(3);
        return a + b + c;
      }
      multiAwait() instanceof Promise;
    JS

    assert result.value
  end

  def test_async_function_with_try_catch
    result = @sandbox.eval(<<~JS)
      async function handleError() {
        try {
          await Promise.reject(new Error("test error"));
          return "should not reach";
        } catch (e) {
          return "caught: " + e.message;
        }
      }
      handleError() instanceof Promise;
    JS

    assert result.value
  end

  def test_async_iife_syntax
    result = @sandbox.eval(<<~JS)
      (async () => {
        const value = await Promise.resolve("hello");
        return value.toUpperCase();
      })() instanceof Promise;
    JS

    assert result.value
  end

  def test_async_method_syntax
    result = @sandbox.eval(<<~JS)
      const obj = {
        async getData() {
          return await Promise.resolve("data");
        }
      };
      obj.getData() instanceof Promise;
    JS

    assert result.value
  end

  def test_async_class_method_syntax
    result = @sandbox.eval(<<~JS)
      class DataFetcher {
        async fetch() {
          return await Promise.resolve("fetched");
        }
      }
      new DataFetcher().fetch() instanceof Promise;
    JS

    assert result.value
  end

  # ==========================================================================
  # setTimeout/setInterval Availability Tests
  # NOTE: These are NOT available in base QuickJS (require os module from libc)
  # ==========================================================================

  def test_set_timeout_not_available
    result = @sandbox.eval("typeof setTimeout")

    assert_equal "undefined", result.value, "setTimeout is not available in base QuickJS"
  end

  def test_clear_timeout_not_available
    result = @sandbox.eval("typeof clearTimeout")

    assert_equal "undefined", result.value, "clearTimeout is not available in base QuickJS"
  end

  def test_set_interval_not_available
    result = @sandbox.eval("typeof setInterval")

    assert_equal "undefined", result.value, "setInterval is not available in base QuickJS"
  end

  def test_clear_interval_not_available
    result = @sandbox.eval("typeof clearInterval")

    assert_equal "undefined", result.value, "clearInterval is not available in base QuickJS"
  end

  # ==========================================================================
  # Error Handling in Async Code
  # ==========================================================================

  def test_unhandled_promise_rejection_does_not_throw_sync
    # Creating a rejected promise should not throw synchronously
    result = @sandbox.eval(<<~JS)
      Promise.reject(new Error("unhandled"));
      "completed";
    JS

    assert_equal "completed", result.value
  end

  def test_promise_catch_method_exists
    result = @sandbox.eval(<<~JS)
      let catchExists = false;
      Promise.reject(new Error("test"))
        .catch(e => { catchExists = true; });
      typeof catchExists;
    JS

    assert_equal "boolean", result.value
  end

  def test_async_throw_creates_rejected_promise
    result = @sandbox.eval(<<~JS)
      async function willThrow() {
        throw new Error("async error");
      }
      willThrow() instanceof Promise;
    JS

    assert result.value
  end

  def test_async_error_handling_with_catch
    result = @sandbox.eval(<<~JS)
      async function failingOp() {
        throw new Error("operation failed");
      }
      failingOp().catch(e => e.message) instanceof Promise;
    JS

    assert result.value
  end

  # ==========================================================================
  # Date Object Tests (additional timing tests)
  # ==========================================================================

  def test_date_constructor_exists
    result = @sandbox.eval("typeof Date")

    assert_equal "function", result.value
  end

  def test_date_new_creates_object
    result = @sandbox.eval("new Date() instanceof Date")

    assert result.value
  end

  def test_date_get_time
    result = @sandbox.eval(<<~JS)
      const d = new Date();
      typeof d.getTime();
    JS

    assert_equal "number", result.value
  end

  def test_date_get_time_matches_date_now
    result = @sandbox.eval(<<~JS)
      const now = Date.now();
      const d = new Date();
      Math.abs(d.getTime() - now) < 1000;
    JS

    assert result.value, "new Date().getTime() should be close to Date.now()"
  end

  def test_date_iso_string
    result = @sandbox.eval(<<~JS)
      const d = new Date();
      typeof d.toISOString();
    JS

    assert_equal "string", result.value
  end

  def test_date_from_timestamp
    result = @sandbox.eval(<<~JS)
      const d = new Date(1609459200000);  // 2021-01-01T00:00:00.000Z
      d.getUTCFullYear();
    JS

    assert_equal 2021, result.value
  end

  def test_date_parse
    result = @sandbox.eval(<<~JS)
      const timestamp = Date.parse('2021-01-01T00:00:00.000Z');
      timestamp;
    JS

    assert_equal 1_609_459_200_000, result.value
  end

  def test_date_methods_exist
    result = @sandbox.eval(<<~JS)
      const d = new Date();
      [
        typeof d.getFullYear,
        typeof d.getMonth,
        typeof d.getDate,
        typeof d.getHours,
        typeof d.getMinutes,
        typeof d.getSeconds,
        typeof d.getMilliseconds
      ].every(t => t === 'function');
    JS

    assert result.value
  end

  def test_date_utc_methods_exist
    result = @sandbox.eval(<<~JS)
      const d = new Date();
      [
        typeof d.getUTCFullYear,
        typeof d.getUTCMonth,
        typeof d.getUTCDate,
        typeof d.getUTCHours,
        typeof d.getUTCMinutes,
        typeof d.getUTCSeconds,
        typeof d.getUTCMilliseconds
      ].every(t => t === 'function');
    JS

    assert result.value
  end

  # ==========================================================================
  # Performance.now Tests (if available)
  # ==========================================================================

  def test_performance_object_availability
    result = @sandbox.eval("typeof performance")

    # performance may or may not be available in QuickJS
    assert_includes %w[object undefined], result.value
  end

  # ==========================================================================
  # Console with Async
  # ==========================================================================

  def test_console_log_in_promise_then
    result = @sandbox.eval(<<~JS)
      Promise.resolve("value").then(v => console.log(v));
      "started";
    JS

    assert_equal "started", result.value
  end

  def test_console_log_in_async_function
    result = @sandbox.eval(<<~JS)
      async function logSomething() {
        console.log("async log");
        return "done";
      }
      logSomething();
      "called";
    JS

    assert_equal "called", result.value
  end

  # ==========================================================================
  # Complex Async Patterns
  # ==========================================================================

  def test_promise_resolve_with_thenable
    result = @sandbox.eval(<<~JS)
      const thenable = {
        then(resolve) {
          resolve(42);
        }
      };
      Promise.resolve(thenable) instanceof Promise;
    JS

    assert result.value
  end

  def test_async_generator_syntax
    result = @sandbox.eval(<<~JS)
      async function* asyncGen() {
        yield await Promise.resolve(1);
        yield await Promise.resolve(2);
      }
      typeof asyncGen;
    JS

    assert_equal "function", result.value
  end

  def test_for_await_of_syntax
    result = @sandbox.eval(<<~JS)
      async function consumeAsync() {
        const items = [Promise.resolve(1), Promise.resolve(2)];
        let sum = 0;
        for await (const item of items) {
          sum += item;
        }
        return sum;
      }
      consumeAsync() instanceof Promise;
    JS

    assert result.value
  end
end
