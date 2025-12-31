# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/quickjs"

# Tests to verify README error documentation is accurate
# NOTE: These tests are adapted for full QuickJS, which supports more ES6+ features
# than MicroQuickJS (const, let, arrow functions, template literals, etc.)
class ErrorDocumentationTest < Minitest::Test
  def setup
    @sandbox = QuickJS::Sandbox.new
  end

  # ==========================================================================
  # SyntaxError Tests
  # ==========================================================================

  def test_syntax_error_incomplete_statement
    error = assert_raises(QuickJS::SyntaxError) do
      @sandbox.eval("var x = ")
    end
    # QuickJS has slightly different error messages than MicroQuickJS
    assert_match(/SyntaxError.*unexpected/, error.message)
  end

  # QuickJS (full version) supports ES6+ features - these should work, not raise errors
  def test_const_keyword_works
    result = @sandbox.eval("const x = 10; x")
    assert_equal 10, result.value
  end

  def test_let_keyword_works
    result = @sandbox.eval("let y = 20; y")
    assert_equal 20, result.value
  end

  def test_arrow_function_works
    result = @sandbox.eval("[1,2,3].map(x => x * 2)")
    assert_equal [2, 4, 6], result.value
  end

  def test_template_literal_works
    @sandbox.set_variable("literal", "world")
    result = @sandbox.eval("`template ${literal}`")
    assert_equal "template world", result.value
  end

  def test_syntax_error_anonymous_function_declaration
    error = assert_raises(QuickJS::SyntaxError) do
      @sandbox.eval("function() {}")
    end
    assert_equal "SyntaxError: function name expected", error.message
  end

  def test_syntax_error_has_stack_attribute
    error = assert_raises(QuickJS::SyntaxError) do
      @sandbox.eval("function test() {")
    end
    assert_respond_to error, :stack
    assert_kind_of String, error.stack
    assert_match(/at <eval>/, error.stack)
  end

  def test_syntax_error_stack_shows_line_number
    error = assert_raises(QuickJS::SyntaxError) do
      @sandbox.eval("var x = 1;\nvar y = 2;\nfunction broken() {")
    end
    # QuickJS shows line numbers in stack traces
    assert_match(/<eval>:3/, error.stack)
  end

  def test_syntax_error_stack_includes_eval_context
    error = assert_raises(QuickJS::SyntaxError) do
      @sandbox.eval("var x = ")
    end
    # Should show <eval> context and line 1
    assert_match(/<eval>:1/, error.stack)
  end

  # ==========================================================================
  # JavascriptError Tests
  # ==========================================================================

  def test_javascript_error_undefined_variable
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("undefinedVariable")
    end
    # QuickJS error message format is slightly different from MicroQuickJS
    assert_match(/ReferenceError.*undefinedVariable.*not defined/, error.message)
  end

  def test_javascript_error_null_property_access
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("null.foo")
    end
    assert_equal "TypeError: cannot read property 'foo' of null", error.message
  end

  def test_javascript_error_calling_non_function
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("var x = {}; x.foo()")
    end
    assert_equal "TypeError: not a function", error.message
  end

  def test_javascript_error_explicit_throw
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("throw new Error('something went wrong')")
    end
    assert_equal "Error: something went wrong", error.message
  end

  def test_javascript_error_null_name_property
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval(<<~JS)
        function processUser(user) {
          return user.name.toUpperCase();
        }
        processUser(null);
      JS
    end
    assert_equal "TypeError: cannot read property 'name' of null", error.message
  end

  def test_javascript_error_custom_type_error
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval(<<~JS)
        function validateAge(age) {
          if (typeof age !== 'number') {
            throw new TypeError('age must be a number, got ' + typeof age);
          }
          return age;
        }
        validateAge("twenty");
      JS
    end
    assert_equal "TypeError: age must be a number, got string", error.message
  end

  def test_javascript_error_custom_range_error
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("throw new RangeError('value out of range')")
    end
    assert_equal "RangeError: value out of range", error.message
  end

  # ==========================================================================
  # Error Type Parsing
  # ==========================================================================

  def test_error_type_can_be_parsed_from_message
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("undefinedVariable")
    end
    error_type = error.message.split(":").first

    assert_equal "ReferenceError", error_type
  end

  # ==========================================================================
  # Stack Trace Tests
  # ==========================================================================

  def test_javascript_error_has_stack_attribute
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval("throw new Error('test')")
    end
    assert_respond_to error, :stack
    assert_kind_of String, error.stack
    assert_match(/at <eval>/, error.stack)
  end

  def test_stack_trace_shows_function_names
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval(<<~JS)
        function innerFunc() {
          throw new Error("inner error");
        }
        function outerFunc() {
          innerFunc();
        }
        outerFunc();
      JS
    end
    assert_match(/at innerFunc/, error.stack)
    assert_match(/at outerFunc/, error.stack)
  end

  def test_stack_trace_shows_line_numbers
    error = assert_raises(QuickJS::JavascriptError) do
      @sandbox.eval(<<~JS)
        var x = 1;
        var y = 2;
        throw new Error("line 3");
      JS
    end
    # Stack should contain line number info
    assert_match(/<eval>:\d+/, error.stack)
  end
end
