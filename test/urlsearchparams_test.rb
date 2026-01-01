# frozen_string_literal: true

require_relative "test_helper"

class URLSearchParamsTest < Minitest::Test
  def setup
    @sandbox = QuickJS::Sandbox.new
    @sandbox.eval(QuickJS::FetchPolyfill::FULL_POLYFILL)
  end

  def test_basic_construction_from_string
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('foo=bar&baz=qux');
      params.get('foo')
    JS
    assert_equal "bar", result.value
  end

  def test_get_returns_first_value
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('key=value1&key=value2');
      params.get('key')
    JS
    assert_equal "value1", result.value
  end

  def test_getall_returns_all_values
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('key=value1&key=value2');
      JSON.stringify(params.getAll('key'))
    JS
    assert_equal %w[value1 value2], JSON.parse(result.value)
  end

  def test_has_checks_existence
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('foo=bar');
      params.has('foo') + ',' + params.has('baz')
    JS
    assert_equal "true,false", result.value
  end

  def test_append_adds_value
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('foo=bar');
      params.append('foo', 'baz');
      params.getAll('foo').length
    JS
    assert_equal 2, result.value
  end

  def test_set_replaces_all_values
    result = @sandbox.eval(<<~JS)
      const params1 = new URLSearchParams('foo=bar&foo=baz');
      params1.set('foo', 'qux');
      params1.getAll('foo').length
    JS
    assert_equal 1, result.value

    result = @sandbox.eval(<<~JS)
      const params2 = new URLSearchParams('foo=bar&foo=baz');
      params2.set('foo', 'qux');
      params2.get('foo')
    JS
    assert_equal "qux", result.value
  end

  def test_delete_removes_key
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('foo=bar');
      params.delete('foo');
      params.has('foo')
    JS
    refute result.value
  end

  def test_tostring_serializes
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('foo=bar&baz=qux');
      params.toString()
    JS
    assert_equal "foo=bar&baz=qux", result.value
  end

  def test_for_each_iterates
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('a=1&b=2&c=3');
      const results = [];
      params.forEach((value, key) => {
        results.push(key + '=' + value);
      });
      results.sort().join(',')
    JS
    assert_equal "a=1,b=2,c=3", result.value
  end

  def test_keys_iterator
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('a=1&b=2');
      const keys = [];
      for (const key of params.keys()) {
        keys.push(key);
      }
      keys.sort().join(',')
    JS
    assert_equal "a,b", result.value
  end

  def test_values_iterator
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('a=1&b=2');
      const values = [];
      for (const value of params.values()) {
        values.push(value);
      }
      values.sort().join(',')
    JS
    assert_equal "1,2", result.value
  end

  def test_entries_iterator
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('b=2&a=1');
      const entries = [];
      for (const entry of params.entries()) {
        entries.push(entry[0] + '=' + entry[1]);
      }
      entries.sort().join(',')
    JS
    assert_equal "a=1,b=2", result.value
  end

  def test_size_property
    result = @sandbox.eval(<<~JS)
      const params1 = new URLSearchParams('a=1&b=2&c=3');
      params1.size
    JS
    assert_equal 3, result.value

    result = @sandbox.eval(<<~JS)
      const params2 = new URLSearchParams('a=1&a=2&a=3');
      params2.size
    JS
    assert_equal 3, result.value
  end

  def test_sort_sorts_keys
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('z=1&a=2&m=3');
      params.sort();
      params.toString()
    JS
    assert_equal "a=2&m=3&z=1", result.value
  end

  def test_construction_from_object
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams({foo: 'bar', baz: 'qux'});
      params.get('foo') + ',' + params.get('baz')
    JS
    assert_equal "bar,qux", result.value
  end

  def test_construction_from_array
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams([['foo', 'bar'], ['baz', 'qux']]);
      params.get('foo') + ',' + params.get('baz')
    JS
    assert_equal "bar,qux", result.value
  end

  def test_construction_from_urlsearchparams
    result = @sandbox.eval(<<~JS)
      const params1 = new URLSearchParams('foo=bar');
      const params2 = new URLSearchParams(params1);
      params2.get('foo')
    JS
    assert_equal "bar", result.value
  end

  def test_leading_question_mark_removed
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('?foo=bar&baz=qux');
      params.get('foo')
    JS
    assert_equal "bar", result.value
  end

  def test_special_characters_encoding
    result = @sandbox.eval(<<~JS)
      const params1 = new URLSearchParams('search=hello world&foo=bar+baz');
      params1.get('search')
    JS
    assert_equal "hello world", result.value

    result = @sandbox.eval(<<~JS)
      const params2 = new URLSearchParams('search=hello world');
      params2.toString()
    JS
    assert_equal "search=hello+world", result.value
  end

  def test_empty_key
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('=value&key=value2');
      params.get('')
    JS
    assert_equal "value", result.value
  end

  def test_empty_value
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('key=&key2=value');
      params.get('key')
    JS
    assert_equal "", result.value
  end

  def test_symbol_iterator_tag
    result = @sandbox.eval(<<~JS)
      const params = new URLSearchParams('a=1');
      Object.prototype.toString.call(params)
    JS
    # The polyfill sets Symbol.toStringTag
    assert_equal "[object URLSearchParams]", result.value
  end
end
