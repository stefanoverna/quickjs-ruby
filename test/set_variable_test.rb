#!/usr/bin/env ruby
# frozen_string_literal: true

require "quickjs"
require "minitest/autorun"

class TestSetVariable < Minitest::Test
  # Test primitive types
  def test_set_integer
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("x", 42)
    result = sandbox.eval("x")

    assert_equal 42, result.value
  end

  def test_set_large_integer
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("bignum", 9_876_543_210)
    result = sandbox.eval("bignum")

    assert_equal 9_876_543_210, result.value
  end

  def test_set_float
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("pi", 3.14159)
    result = sandbox.eval("pi")

    assert_in_delta 3.14159, result.value, 0.00001
  end

  def test_set_string
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("greeting", "Hello World")
    result = sandbox.eval("greeting")

    assert_equal "Hello World", result.value
  end

  def test_set_boolean_true
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("flag", true)
    result = sandbox.eval("flag")

    assert result.value
  end

  def test_set_boolean_false
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("flag", false)
    result = sandbox.eval("flag")

    refute result.value
  end

  def test_set_nil
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("nothing", nil)
    result = sandbox.eval("nothing === null")

    assert result.value
  end

  def test_set_symbol
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("sym", :my_symbol)
    result = sandbox.eval("sym")

    assert_equal "my_symbol", result.value
  end

  # Test arrays
  def test_set_simple_array
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("arr", [1, 2, 3, 4, 5])
    result = sandbox.eval("arr.length")

    assert_equal 5, result.value

    result = sandbox.eval("arr[0]")

    assert_equal 1, result.value

    result = sandbox.eval("arr[4]")

    assert_equal 5, result.value
  end

  def test_set_mixed_array
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("mixed", [1, "two", 3.0, true, nil])

    result = sandbox.eval("mixed[0]")

    assert_equal 1, result.value

    result = sandbox.eval("mixed[1]")

    assert_equal "two", result.value

    result = sandbox.eval("mixed[2]")

    assert_in_delta(3.0, result.value)

    result = sandbox.eval("mixed[3]")

    assert result.value

    result = sandbox.eval("mixed[4] === null")

    assert result.value
  end

  def test_set_nested_array
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("nested", [[1, 2], [3, 4], [5, 6]])

    result = sandbox.eval("nested[0][0]")

    assert_equal 1, result.value

    result = sandbox.eval("nested[1][1]")

    assert_equal 4, result.value

    result = sandbox.eval("nested[2][0]")

    assert_equal 5, result.value
  end

  def test_array_methods
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("numbers", [1, 2, 3, 4, 5])

    result = sandbox.eval(<<~JS)
      var sum = 0;
      for (var i = 0; i < numbers.length; i++) {
        sum += numbers[i];
      }
      sum;
    JS
    assert_equal 15, result.value
  end

  # Test hashes/objects
  def test_set_simple_hash
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("obj", { name: "Alice", age: 30 })

    result = sandbox.eval("obj.name")

    assert_equal "Alice", result.value

    result = sandbox.eval("obj.age")

    assert_equal 30, result.value
  end

  def test_set_hash_with_string_keys
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("person", { "name" => "Bob", "city" => "NYC" })

    result = sandbox.eval("person.name")

    assert_equal "Bob", result.value

    result = sandbox.eval("person.city")

    assert_equal "NYC", result.value
  end

  def test_set_nested_hash
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("data", {
                           user: {
                             name: "Charlie",
                             address: {
                               street: "Main St",
                               city: "Boston"
                             }
                           }
                         })

    result = sandbox.eval("data.user.name")

    assert_equal "Charlie", result.value

    result = sandbox.eval("data.user.address.street")

    assert_equal "Main St", result.value

    result = sandbox.eval("data.user.address.city")

    assert_equal "Boston", result.value
  end

  def test_set_hash_with_mixed_values
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("config", {
                           port: 8080,
                           host: "localhost",
                           ssl: true,
                           timeout: 30.5,
                           enabled: false
                         })

    result = sandbox.eval("config.port")

    assert_equal 8080, result.value

    result = sandbox.eval("config.host")

    assert_equal "localhost", result.value

    result = sandbox.eval("config.ssl")

    assert result.value

    result = sandbox.eval("config.timeout")

    assert_in_delta 30.5, result.value, 0.01

    result = sandbox.eval("config.enabled")

    refute result.value
  end

  # Test complex structures
  def test_set_hash_with_array_values
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("data", {
                           items: [1, 2, 3],
                           names: %w[Alice Bob Charlie]
                         })

    result = sandbox.eval("data.items[0]")

    assert_equal 1, result.value

    result = sandbox.eval("data.names[2]")

    assert_equal "Charlie", result.value
  end

  def test_set_array_with_hash_elements
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("users", [
                           { name: "Alice", age: 25 },
                           { name: "Bob", age: 30 },
                           { name: "Charlie", age: 35 }
                         ])

    result = sandbox.eval("users[0].name")

    assert_equal "Alice", result.value

    result = sandbox.eval("users[1].age")

    assert_equal 30, result.value

    result = sandbox.eval("users[2].name")

    assert_equal "Charlie", result.value
  end

  def test_set_deeply_nested_structure
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("complex", {
                           level1: {
                             level2: {
                               level3: {
                                 array: [
                                   { value: 42 },
                                   { value: 43 }
                                 ]
                               }
                             }
                           }
                         })

    result = sandbox.eval("complex.level1.level2.level3.array[0].value")

    assert_equal 42, result.value

    result = sandbox.eval("complex.level1.level2.level3.array[1].value")

    assert_equal 43, result.value
  end

  # Test multiple variables
  def test_set_multiple_variables
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("x", 10)
    sandbox.set_variable("y", 20)
    sandbox.set_variable("z", 30)

    result = sandbox.eval("x + y + z")

    assert_equal 60, result.value
  end

  def test_variable_persistence
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("counter", 5)

    result1 = sandbox.eval("counter")

    assert_equal 5, result1.value

    result2 = sandbox.eval("counter * 2")

    assert_equal 10, result2.value

    # Variable should persist across eval calls
    result3 = sandbox.eval("counter + 10")

    assert_equal 15, result3.value
  end

  def test_overwrite_variable
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("value", 100)

    result1 = sandbox.eval("value")

    assert_equal 100, result1.value

    sandbox.set_variable("value", 200)

    result2 = sandbox.eval("value")

    assert_equal 200, result2.value
  end

  # Test usage in expressions
  def test_use_in_arithmetic
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("a", 10)
    sandbox.set_variable("b", 5)

    result = sandbox.eval("a + b")

    assert_equal 15, result.value

    result = sandbox.eval("a * b")

    assert_equal 50, result.value

    result = sandbox.eval("a - b")

    assert_equal 5, result.value
  end

  def test_use_in_string_operations
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("first", "Hello")
    sandbox.set_variable("second", "World")

    result = sandbox.eval("first + ' ' + second")

    assert_equal "Hello World", result.value
  end

  def test_use_in_conditionals
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("enabled", true)

    result = sandbox.eval("enabled ? 'yes' : 'no'")

    assert_equal "yes", result.value

    sandbox.set_variable("enabled", false)

    result = sandbox.eval("enabled ? 'yes' : 'no'")

    assert_equal "no", result.value
  end

  def test_use_in_loops
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("limit", 5)

    code = <<~JS
      var sum = 0;
      for (var i = 0; i < limit; i++) {
        sum += i;
      }
      sum;
    JS

    result = sandbox.eval(code)

    assert_equal 10, result.value
  end

  def test_array_iteration
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("items", [10, 20, 30, 40, 50])

    code = <<~JS
      var total = 0;
      for (var i = 0; i < items.length; i++) {
        total += items[i];
      }
      total;
    JS

    result = sandbox.eval(code)

    assert_equal 150, result.value
  end

  def test_object_property_access
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("config", {
                           database: "postgres",
                           host: "localhost",
                           port: 5432
                         })

    result = sandbox.eval("config.database + '://' + config.host + ':' + config.port")

    assert_equal "postgres://localhost:5432", result.value
  end

  # Test real-world scenarios
  def test_user_script_with_input_data
    sandbox = QuickJS::Sandbox.new

    # Simulate passing context to user script
    sandbox.set_variable("items", [
                           { price: 10, quantity: 2 },
                           { price: 5, quantity: 3 },
                           { price: 15, quantity: 1 }
                         ])

    user_script = <<~JS
      var total = 0;
      for (var i = 0; i < items.length; i++) {
        total += items[i].price * items[i].quantity;
      }
      total;
    JS

    result = sandbox.eval(user_script)

    assert_equal 50, result.value
  end

  def test_template_rendering
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("data", {
                           name: "Alice",
                           unread: 5
                         })

    template = "'Hello ' + data.name + '! You have ' + data.unread + ' unread messages.'"

    result = sandbox.eval(template)

    assert_equal "Hello Alice! You have 5 unread messages.", result.value
  end

  def test_data_transformation
    sandbox = QuickJS::Sandbox.new
    sandbox.set_variable("payload", {
                           user: "alice",
                           action: "login",
                           timestamp: 1_234_567_890
                         })

    transformation = <<~JS
      JSON.stringify({
        username: payload.user.toUpperCase(),
        event_type: payload.action,
        ts: payload.timestamp
      })
    JS

    result = sandbox.eval(transformation)
    # Result is JSON string representation
    assert_match(/ALICE/, result.value)
    assert_match(/login/, result.value)
  end

  # Test error cases
  def test_invalid_variable_name
    sandbox = QuickJS::Sandbox.new

    # Empty string should still work (though not recommended)
    assert_raises(ArgumentError) do
      sandbox.set_variable("", 42)
    end
  end
end
