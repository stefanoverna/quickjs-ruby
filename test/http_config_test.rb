#!/usr/bin/env ruby
# frozen_string_literal: true

require "quickjs"
require "minitest/autorun"

class TestHTTPConfig < Minitest::Test
  # Allowlist tests
  def test_allowlist_exact_match
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://api.github.com/users/octocat"]
    )

    assert config.allowed?("https://api.github.com/users/octocat")
    refute config.allowed?("https://api.github.com/users/other")
  end

  def test_allowlist_wildcard_path
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://api.github.com/users/*"]
    )

    assert config.allowed?("https://api.github.com/users/octocat")
    assert config.allowed?("https://api.github.com/users/anyone")
    refute config.allowed?("https://api.github.com/repos/foo")
  end

  def test_allowlist_double_wildcard
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://api.github.com/**"]
    )

    assert config.allowed?("https://api.github.com/users/octocat")
    assert config.allowed?("https://api.github.com/repos/foo/bar")
    refute config.allowed?("https://other.com/anything")
  end

  # Denylist tests
  def test_denylist_exact_match
    config = QuickJS::HTTPConfig.new(
      denylist: ["https://evil.com/malware"]
    )

    refute config.allowed?("https://evil.com/malware")
    assert config.allowed?("https://evil.com/other")
    assert config.allowed?("https://safe.com/anything")
  end

  def test_denylist_wildcard_path
    config = QuickJS::HTTPConfig.new(
      denylist: ["https://evil.com/*"]
    )

    refute config.allowed?("https://evil.com/malware")
    refute config.allowed?("https://evil.com/anything")
    assert config.allowed?("https://evil.com/nested/path") # * doesn't match /
    assert config.allowed?("https://safe.com/anything")
  end

  def test_denylist_double_wildcard
    config = QuickJS::HTTPConfig.new(
      denylist: ["https://evil.com/**"]
    )

    refute config.allowed?("https://evil.com/malware")
    refute config.allowed?("https://evil.com/nested/deep/path")
    assert config.allowed?("https://safe.com/anything")
    assert config.allowed?("https://other.com/path")
  end

  def test_denylist_multiple_patterns
    config = QuickJS::HTTPConfig.new(
      denylist: ["https://evil.com/**", "https://*.malware.net/**"]
    )

    refute config.allowed?("https://evil.com/anything")
    refute config.allowed?("https://bad.malware.net/path")
    assert config.allowed?("https://safe.com/anything")
  end

  def test_cannot_use_both_allowlist_and_denylist
    error = assert_raises(QuickJS::ArgumentError) do
      QuickJS::HTTPConfig.new(
        allowlist: ["https://api.github.com/**"],
        denylist: ["https://evil.com/**"]
      )
    end
    assert_match(/Cannot specify both/, error.message)
  end

  def test_denylist_mode_predicate
    allowlist_config = QuickJS::HTTPConfig.new(allowlist: ["https://api.github.com/**"])
    denylist_config = QuickJS::HTTPConfig.new(denylist: ["https://evil.com/**"])

    refute_predicate allowlist_config, :denylist_mode?
    assert_predicate denylist_config, :denylist_mode?
  end

  def test_port_validation
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://api.example.com/**"],
      allowed_ports: [443]
    )

    assert config.allowed?("https://api.example.com/data")
    refute config.allowed?("https://api.example.com:8080/data")
  end

  def test_blocked_private_ips
    config = QuickJS::HTTPConfig.new(block_private_ips: true)

    assert config.blocked_ip?("127.0.0.1")
    assert config.blocked_ip?("10.0.0.1")
    assert config.blocked_ip?("192.168.1.1")
    assert config.blocked_ip?("172.16.0.1")
    assert config.blocked_ip?("169.254.169.254")

    refute config.blocked_ip?("8.8.8.8")
    refute config.blocked_ip?("1.1.1.1")
  end

  def test_allowed_private_ips_when_disabled
    config = QuickJS::HTTPConfig.new(block_private_ips: false)

    refute config.blocked_ip?("127.0.0.1")
    refute config.blocked_ip?("10.0.0.1")
  end

  def test_validate_url_not_in_allowlist
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://allowed.com/**"]
    )

    error = assert_raises(QuickJS::HTTPBlockedError) do
      config.validate_url!("https://evil.com/data")
    end
    assert_match(/not in allowlist/, error.message)
  end

  def test_validate_url_in_denylist
    config = QuickJS::HTTPConfig.new(
      denylist: ["https://evil.com/**"]
    )

    error = assert_raises(QuickJS::HTTPBlockedError) do
      config.validate_url!("https://evil.com/data")
    end
    assert_match(/matches denylist/, error.message)
  end

  def test_validate_url_blocked_ip
    config = QuickJS::HTTPConfig.new(
      allowlist: ["http://localhost/**"],
      block_private_ips: true
    )

    # localhost resolves to 127.0.0.1 which is blocked
    error = assert_raises(QuickJS::HTTPBlockedError) do
      config.validate_url!("http://localhost/admin")
    end
    assert_match(/blocked IP/, error.message)
  end

  def test_validate_method
    config = QuickJS::HTTPConfig.new

    assert_equal "GET", config.validate_method("get")
    assert_equal "POST", config.validate_method("post")
    assert_equal "PUT", config.validate_method("PUT")

    error = assert_raises(QuickJS::HTTPBlockedError) do
      config.validate_method("TRACE")
    end
    assert_match(/not allowed/, error.message)
  end

  def test_default_configuration
    config = QuickJS::HTTPConfig.new

    assert_equal 10, config.max_requests
    assert_equal 5000, config.request_timeout
    assert_equal 1_048_576, config.max_request_size
    assert_equal 1_048_576, config.max_response_size
    assert_equal [80, 443], config.allowed_ports
  end

  def test_custom_configuration
    config = QuickJS::HTTPConfig.new(
      max_requests: 5,
      request_timeout: 1000,
      allowed_ports: [443]
    )

    assert_equal 5, config.max_requests
    assert_equal 1000, config.request_timeout
    assert_equal [443], config.allowed_ports
  end

  def test_empty_allowlist_blocks_all
    config = QuickJS::HTTPConfig.new(allowlist: [])

    refute config.allowed?("https://any.com/path")
  end

  def test_empty_denylist_blocks_all
    config = QuickJS::HTTPConfig.new(denylist: [])

    refute config.allowed?("https://any.com/path")
  end

  def test_subdomain_wildcard
    config = QuickJS::HTTPConfig.new(
      allowlist: ["https://*.example.com/api/*"]
    )

    assert config.allowed?("https://api.example.com/api/users")
    assert config.allowed?("https://beta.example.com/api/data")
    refute config.allowed?("https://example.com/api/users")  # No subdomain
    refute config.allowed?("https://api.example.com/other")  # Wrong path
  end

  def test_subdomain_wildcard_denylist
    config = QuickJS::HTTPConfig.new(
      denylist: ["https://*.evil.com/**"]
    )

    refute config.allowed?("https://api.evil.com/data")
    refute config.allowed?("https://www.evil.com/path")
    assert config.allowed?("https://evil.com/path") # No subdomain, not blocked
    assert config.allowed?("https://safe.com/path")
  end

  def test_protocol_and_subdomain_wildcard_denylist
    config = QuickJS::HTTPConfig.new(
      denylist: ["**://*.datocms.com/**"]
    )

    # Should block both http and https with any subdomain
    refute config.allowed?("https://site-api.datocms.com/test")
    refute config.allowed?("http://site-api.datocms.com/test")
    refute config.allowed?("https://api.datocms.com/foo")
    refute config.allowed?("http://www.datocms.com/bar")

    # Should NOT block URLs without subdomain (pattern has *.datocms.com)
    assert config.allowed?("https://datocms.com/test")

    # Should NOT block other domains
    assert config.allowed?("https://example.com/test")
  end
end
