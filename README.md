# QuickJS - JavaScript Sandbox for Ruby

[![Gem Version](https://badge.fury.io/rb/quickjs.svg)](https://badge.fury.io/rb/quickjs)

**QuickJS** provides a JavaScript execution environment for Ruby applications with resource controls and isolation features. Built on [QuickJS](https://bellard.org/quickjs/) (a fast JavaScript engine by Fabrice Bellard), it offers strict memory limits, CPU timeouts, and sandboxed execution.

This gem offers the same API as [mquickjs-ruby](https://github.com/stefanoverna/mquickjs-ruby) but uses the full QuickJS engine instead of MicroQuickJS.

## Features

- **Strict Memory Limits** - Fixed memory allocation, no dynamic growth
- **CPU Timeout Enforcement** - Configurable execution time limits
- **Sandboxed Execution** - Isolated from file system and network
- **Console Output Limits** - Prevent memory exhaustion via console.log
- **HTTP Security Controls** - Allowlist/denylist, rate limiting, IP blocking
- **Full ES5+ Support** - Unlike MicroQuickJS, supports modern JavaScript features

## Installation

Add to your Gemfile:

```ruby
gem 'quickjs'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install quickjs
```

## Quick Start

```ruby
require 'quickjs'

# Simple evaluation
result = QuickJS.eval("2 + 2")
puts result.value  # => 4

# With custom limits
sandbox = QuickJS::Sandbox.new(
  memory_limit: 100_000,      # 100KB memory limit
  timeout_ms: 1000,            # 1 second timeout
  console_log_max_size: 50_000 # 50KB console output limit
)

# Run code
result = sandbox.eval(<<~JS)
  function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
  }
  fibonacci(10);
JS

puts result.value           # => 55
puts result.console_output  # => (any console.log output)
```

## API

This gem provides the same API as mquickjs-ruby. See the [mquickjs-ruby documentation](https://github.com/stefanoverna/mquickjs-ruby) for detailed usage examples.

### Main Methods

- `QuickJS.eval(code, options = {})` - One-shot evaluation
- `QuickJS::Sandbox.new(options = {})` - Create reusable sandbox
- `Sandbox#eval(code)` - Execute JavaScript code
- `Sandbox#set_variable(name, value)` - Set global variables from Ruby

### Configuration Options

- `memory_limit` - Memory limit in bytes (default: 50,000, minimum: 10,000)
- `timeout_ms` - Timeout in milliseconds (default: 5,000)
- `console_log_max_size` - Console output limit (default: 10,000)
- `http` - HTTP configuration for fetch() support

## HTTP Requests

Enable HTTP requests with security controls:

```ruby
sandbox = QuickJS::Sandbox.new(
  http: {
    allowlist: ['https://api.github.com/**'],
    max_requests: 5
  }
)

result = sandbox.eval(<<~JS)
  var response = fetch('https://api.github.com/users/octocat');
  JSON.parse(response.body).login;
JS

result.value  # => "octocat"
```

## Development

```bash
# Clone the repository
git clone https://github.com/stefanoverna/quickjs-ruby.git
cd quickjs-ruby

# Install dependencies
bundle install

# Build and test
rake
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

- **QuickJS**: Created by Fabrice Bellard - https://bellard.org/quickjs/
- **mquickjs-ruby**: Original gem by Stefano Verna - https://github.com/stefanoverna/mquickjs-ruby
