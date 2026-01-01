# frozen_string_literal: true

require_relative "test_helper"

class URLTest < Minitest::Test
  def setup
    @sandbox = QuickJS::Sandbox.new
    @sandbox.eval(QuickJS::FetchPolyfill::FULL_POLYFILL)
  end

  def test_basic_url_parsing
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/path');
      url.href
    JS
    assert_equal "https://example.com/path", result.value
  end

  def test_protocol
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com');
      url.protocol
    JS
    assert_equal "https:", result.value
  end

  def test_hostname
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com');
      url.hostname
    JS
    assert_equal "example.com", result.value
  end

  def test_port
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com:8080');
      url.port
    JS
    assert_equal "8080", result.value
  end

  def test_host
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com:8080');
      url.host
    JS
    assert_equal "example.com:8080", result.value
  end

  def test_pathname
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/path/to/page');
      url.pathname
    JS
    assert_equal "/path/to/page", result.value
  end

  def test_search
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com?key=value');
      url.search
    JS
    assert_equal "?key=value", result.value
  end

  def test_hash
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com#section');
      url.hash
    JS
    assert_equal "#section", result.value
  end

  def test_origin
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com:8080');
      url.origin
    JS
    assert_equal "https://example.com:8080", result.value

    result = @sandbox.eval(<<~JS)
      const url2 = new URL('https://example.com');
      url2.origin
    JS
    assert_equal "https://example.com", result.value
  end

  def test_search_params_property
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com?key=value&foo=bar');
      url.searchParams.get('key')
    JS
    assert_equal "value", result.value
  end

  def test_search_params_mutation_updates_search
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com');
      url.searchParams.append('foo', 'bar');
      url.searchParams.get('foo')
    JS
    assert_equal "bar", result.value
  end

  def test_search_params_set_updates_url_href
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/?foo=bar');
      url.searchParams.set('foo', 'baz');
      url.href
    JS
    assert_equal "https://example.com/?foo=baz", result.value
  end

  def test_search_params_append_updates_url_href
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/?foo=bar');
      url.searchParams.append('new', 'value');
      url.href
    JS
    assert_equal "https://example.com/?foo=bar&new=value", result.value
  end

  def test_search_params_delete_updates_url_href
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/?foo=bar&remove=me');
      url.searchParams.delete('remove');
      url.href
    JS
    assert_equal "https://example.com/?foo=bar", result.value
  end

  def test_search_mutation_updates_search_params
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com?foo=bar');
      url.searchParams.get('foo')
    JS
    assert_equal "bar", result.value
  end

  def test_setting_search_updates_search_params
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/?old=value');
      url.search = '?new=value';
      url.searchParams.get('new')
    JS
    assert_equal "value", result.value

    result = @sandbox.eval(<<~JS)
      const url2 = new URL('https://example.com/?old=value');
      url2.search = '?new=value';
      url2.searchParams.has('old')
    JS
    refute result.value
  end

  def test_setting_href_updates_search_params
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/?old=value');
      url.href = 'https://other.com/?new=value';
      url.searchParams.get('new')
    JS
    assert_equal "value", result.value
  end

  def test_relative_url_with_base
    result = @sandbox.eval(<<~JS)
      const url = new URL('/path', 'https://example.com');
      url.href
    JS
    assert_equal "https://example.com/path", result.value
  end

  def test_relative_url_with_base_and_path
    result = @sandbox.eval(<<~JS)
      const url = new URL('page.html', 'https://example.com/path/to/');
      url.href
    JS
    assert_equal "https://example.com/path/to/page.html", result.value
  end

  def test_protocol_relative_url
    result = @sandbox.eval(<<~JS)
      const url = new URL('//example.com/path', 'https://base.com');
      url.href
    JS
    assert_equal "https://example.com/path", result.value
  end

  def test_to_string
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/path');
      url.toString()
    JS
    assert_equal "https://example.com/path", result.value
  end

  def test_to_json
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/path');
      url.toJSON()
    JS
    assert_equal "https://example.com/path", result.value
  end

  def test_setting_href_rebuilds_url
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/old');
      url.href = 'https://new.com/path';
      url.hostname
    JS
    assert_equal "new.com", result.value
  end

  def test_setting_protocol
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com');
      url.protocol = 'http:';
      url.href
    JS
    assert_equal "http://example.com/", result.value
  end

  def test_setting_hostname
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com');
      url.hostname = 'newhost.com';
      url.href
    JS
    assert_equal "https://newhost.com/", result.value
  end

  def test_setting_port
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com');
      url.port = '9000';
      url.href
    JS
    assert_equal "https://example.com:9000/", result.value
  end

  def test_setting_pathname
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/old');
      url.pathname = '/new/path';
      url.href
    JS
    assert_equal "https://example.com/new/path", result.value
  end

  def test_setting_hash
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com');
      url.hash = '#section';
      url.href
    JS
    assert_equal "https://example.com/#section", result.value
  end

  def test_empty_search_params
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com');
      url.searchParams.get('foo')
    JS
    assert_nil result.value
  end

  def test_url_with_all_components
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://user:pass@example.com:8080/path?q=test#hash');
      url.href
    JS
    assert_equal "https://user:pass@example.com:8080/path?q=test#hash", result.value
  end

  def test_username_password_parsing
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://user:pass@example.com/');
      url.username
    JS
    assert_equal "user", result.value

    result = @sandbox.eval(<<~JS)
      const url2 = new URL('https://user:pass@example.com/');
      url2.password
    JS
    assert_equal "pass", result.value
  end

  def test_setting_username_password
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com/');
      url.username = 'newuser';
      url.password = 'newpass';
      url.href
    JS
    assert_equal "https://newuser:newpass@example.com/", result.value
  end

  def test_url_with_username_only
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://user@example.com/');
      url.href
    JS
    assert_equal "https://user@example.com/", result.value
  end

  def test_clearing_username_password
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://user:pass@example.com/');
      url.username = '';
      url.password = '';
      url.href
    JS
    assert_equal "https://example.com/", result.value
  end

  def test_symbol_to_string_tag
    result = @sandbox.eval(<<~JS)
      const url = new URL('https://example.com');
      Object.prototype.toString.call(url)
    JS
    assert_equal "[object URL]", result.value
  end
end
