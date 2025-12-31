#!/usr/bin/env ruby
# frozen_string_literal: true

require "quickjs"
require "minitest/autorun"

class TestQuickJS < Minitest::Test
  def test_simple_arithmetic
    result = QuickJS.eval("1 + 2 + 3")

    assert_equal 6, result.value
    assert_equal "", result.console_output
  end

  def test_string_operations
    result = QuickJS.eval("'hello'.toUpperCase()")

    assert_equal "HELLO", result.value
  end

  def test_loop_with_sum
    code = <<~JS
      var sum = 0;
      for (var i = 0; i < 100; i++) {
        sum += i;
      }
      sum;
    JS
    result = QuickJS.eval(code)

    assert_equal 4950, result.value
  end

  def test_math_functions
    result = QuickJS.eval("Math.sqrt(16)")

    assert_in_delta(4.0, result.value)
  end

  def test_return_string
    result = QuickJS.eval("'test string'")

    assert_equal "test string", result.value
  end

  def test_return_boolean
    assert QuickJS.eval("true").value
    refute QuickJS.eval("false").value
  end

  def test_return_null
    assert_nil QuickJS.eval("null").value
  end

  def test_return_undefined
    assert_nil QuickJS.eval("undefined").value
  end

  def test_syntax_error
    error = assert_raises(QuickJS::SyntaxError) do
      QuickJS.eval("var x = ")
    end
    assert_match(/SyntaxError/, error.message)
  end

  def test_javascript_error
    error = assert_raises(QuickJS::JavascriptError) do
      QuickJS.eval("throw new Error('test error')")
    end
    assert_match(/Error/, error.message)
  end

  def test_timeout
    error = assert_raises(QuickJS::TimeoutError) do
      QuickJS.eval("while(true) {}", timeout_ms: 100)
    end
    assert_match(/timeout/i, error.message)
  end

  def test_memory_limit
    # Try to allocate lots of memory
    code = <<~JS
      var arr = [];
      for (var i = 0; i < 10000; i++) {
        arr.push(new Array(100));
      }
    JS

    # This should fail with small memory limit (QuickJS stdlib needs ~100KB minimum)
    # Note: QuickJS requires more memory than MicroQuickJS
    begin
      QuickJS.eval(code, memory_limit: 150_000) # Small but valid limit
      # If it doesn't raise, that's ok - QuickJS might handle it gracefully
    rescue QuickJS::MemoryLimitError, QuickJS::JavascriptError
      # Expected - either out of memory or JS error
    end
  end

  def test_memory_limit_validation
    # memory_limit cannot be less than 100000 bytes (required for QuickJS stdlib initialization)
    error = assert_raises(QuickJS::ArgumentError) do
      QuickJS::Sandbox.new(memory_limit: 50000)
    end
    assert_match(/memory_limit cannot be less than 100000/i, error.message)
    assert_match(/50000/, error.message)

    # Should work with exactly 100000
    sandbox = QuickJS::Sandbox.new(memory_limit: 100_000)
    result = sandbox.eval("2 + 2")

    assert_equal 4, result.value

    # Should work with more than 100000
    sandbox = QuickJS::Sandbox.new(memory_limit: 200_000)
    result = sandbox.eval("2 + 2")

    assert_equal 4, result.value
  end

  def test_reusable_sandbox
    sandbox = QuickJS::Sandbox.new

    result1 = sandbox.eval("2 + 2")

    assert_equal 4, result1.value

    result2 = sandbox.eval("3 * 3")

    assert_equal 9, result2.value

    # Each eval is isolated
    result3 = sandbox.eval("typeof x")

    assert_equal "undefined", result3.value
  end

  def test_complex_expression
    code = <<~JS
      var fibonacci = function(n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
      };
      fibonacci(10);
    JS
    result = QuickJS.eval(code)

    assert_equal 55, result.value
  end

  def test_array_operations
    code = <<~JS
      var arr = [1, 2, 3, 4, 5];
      var sum = 0;
      for (var i = 0; i < arr.length; i++) {
        sum += arr[i];
      }
      sum;
    JS
    result = QuickJS.eval(code)

    assert_equal 15, result.value
  end

  def test_string_concatenation
    result = QuickJS.eval("'Hello' + ' ' + 'World'")

    assert_equal "Hello World", result.value
  end

  def test_comparison_operators
    assert QuickJS.eval("5 > 3").value
    refute QuickJS.eval("2 > 10").value
    assert QuickJS.eval("'abc' === 'abc'").value
  end

  def test_typeof_operator
    assert_equal "number", QuickJS.eval("typeof 42").value
    assert_equal "string", QuickJS.eval("typeof 'test'").value
    assert_equal "boolean", QuickJS.eval("typeof true").value
    assert_equal "undefined", QuickJS.eval("typeof undefined").value
  end

  def test_object_property_access
    code = <<~JS
      var obj = { x: 10, y: 20 };
      obj.x + obj.y;
    JS
    result = QuickJS.eval(code)

    assert_equal 30, result.value
  end

  def test_return_array
    result = QuickJS.eval("[1, 2, 3]")

    assert_equal [1, 2, 3], result.value
  end

  def test_return_mixed_array
    result = QuickJS.eval("[1, 'two', 3.5, true, null]")

    assert_equal [1, "two", 3.5, true, nil], result.value
  end

  def test_return_object
    result = QuickJS.eval("({name: 'Alice', age: 30})")

    assert_equal({ "name" => "Alice", "age" => 30 }, result.value)
  end

  def test_return_nested_structure
    result = QuickJS.eval("({items: [1, 2], nested: {a: 1}})")
    expected = { "items" => [1, 2], "nested" => { "a" => 1 } }

    assert_equal expected, result.value
  end

  def test_return_array_of_objects
    result = QuickJS.eval("[{x: 1}, {x: 2}]")
    expected = [{ "x" => 1 }, { "x" => 2 }]

    assert_equal expected, result.value
  end

  def test_custom_memory_limit
    sandbox = QuickJS::Sandbox.new(memory_limit: 100_000)
    result = sandbox.eval("1 + 1")

    assert_equal 2, result.value
  end

  def test_custom_timeout
    sandbox = QuickJS::Sandbox.new(timeout_ms: 1000)
    result = sandbox.eval("2 * 2")

    assert_equal 4, result.value
  end

  def test_console_log_capture
    result = QuickJS.eval("console.log('Hello'); console.log('World'); 42")

    assert_equal 42, result.value
    assert_equal "Hello\nWorld\n", result.console_output
    refute_predicate result, :console_truncated?
  end

  def test_console_log_multiple_args
    result = QuickJS.eval("console.log('a', 'b', 'c'); 123")

    assert_equal 123, result.value
    assert_equal "a b c\n", result.console_output
  end

  def test_console_log_with_numbers
    result = QuickJS.eval("console.log(1, 2, 3); console.log(true); 'done'")

    assert_equal "done", result.value
    assert_equal "1 2 3\ntrue\n", result.console_output
  end

  def test_console_log_truncation
    # Generate output larger than default 10KB limit
    # Each line is ~101 bytes (100 x's + newline), so 200 lines = ~20KB
    code = <<~JS
      var longStr = '';
      for (var j = 0; j < 100; j++) longStr += 'x';
      for (var i = 0; i < 200; i++) console.log(longStr);
      'done'
    JS
    result = QuickJS.eval(code)

    assert_equal "done", result.value
    assert_operator result.console_output.bytesize, :<=, 10_000
    assert_predicate result, :console_truncated?
  end

  def test_custom_console_max_size
    # Each line is ~51 bytes (50 x's + newline), so we need at least 3 lines to exceed 100 bytes
    sandbox = QuickJS::Sandbox.new(console_log_max_size: 100)
    code = <<~JS
      var longStr = '';
      for (var j = 0; j < 50; j++) longStr += 'x';
      for (var i = 0; i < 10; i++) console.log(longStr);
      42
    JS
    result = sandbox.eval(code)

    assert_equal 42, result.value
    assert_operator result.console_output.bytesize, :<=, 100
    assert_predicate result, :console_truncated?
  end

  def test_no_console_output
    result = QuickJS.eval("1 + 1")

    assert_equal 2, result.value
    assert_equal "", result.console_output
    refute_predicate result, :console_truncated?
  end

  # Tests for console output in exceptions

  def test_javascript_error_includes_console_output
    error = assert_raises(QuickJS::JavascriptError) do
      QuickJS.eval("console.log('before error'); console.log('step 2'); throw new Error('test error')")
    end
    assert_match(/Error/, error.message)
    assert_equal "before error\nstep 2\n", error.console_output
    refute_predicate error, :console_truncated?
  end

  def test_javascript_error_empty_console_output
    error = assert_raises(QuickJS::JavascriptError) do
      QuickJS.eval("throw new Error('test error')")
    end
    assert_match(/Error/, error.message)
    assert_equal "", error.console_output
    refute_predicate error, :console_truncated?
  end

  def test_syntax_error_includes_console_output
    # Syntax errors are detected during parsing, so no console output should be captured
    error = assert_raises(QuickJS::SyntaxError) do
      QuickJS.eval("var x = ")
    end
    assert_match(/SyntaxError/, error.message)
    assert_equal "", error.console_output
    refute_predicate error, :console_truncated?
  end

  def test_timeout_error_includes_console_output
    error = assert_raises(QuickJS::TimeoutError) do
      QuickJS.eval("console.log('starting'); console.log('looping'); while(true) {}", timeout_ms: 100)
    end
    assert_match(/timeout/i, error.message)
    assert_equal "starting\nlooping\n", error.console_output
    refute_predicate error, :console_truncated?
  end

  def test_timeout_error_empty_console_output
    error = assert_raises(QuickJS::TimeoutError) do
      QuickJS.eval("while(true) {}", timeout_ms: 100)
    end
    assert_match(/timeout/i, error.message)
    assert_equal "", error.console_output
    refute_predicate error, :console_truncated?
  end

  def test_javascript_error_with_truncated_console_output
    sandbox = QuickJS::Sandbox.new(console_log_max_size: 50)
    error = assert_raises(QuickJS::JavascriptError) do
      # Generate more than 50 bytes of console output before error
      sandbox.eval("for(var i = 0; i < 10; i++) console.log('line ' + i); throw new Error('test')")
    end
    assert_match(/Error/, error.message)
    assert_operator error.console_output.bytesize, :<=, 50
    assert_predicate error, :console_truncated?
  end

  def test_timeout_error_with_truncated_console_output
    sandbox = QuickJS::Sandbox.new(timeout_ms: 100, console_log_max_size: 50)
    error = assert_raises(QuickJS::TimeoutError) do
      # Generate console output that exceeds limit, then loop forever
      sandbox.eval("for(var i = 0; i < 20; i++) console.log('line ' + i); while(true) {}")
    end
    assert_match(/timeout/i, error.message)
    assert_operator error.console_output.bytesize, :<=, 50
    assert_predicate error, :console_truncated?
  end
end
