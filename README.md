# QuickJS - JavaScript Sandbox for Ruby

[![Gem Version](https://badge.fury.io/rb/quickjs.svg)](https://badge.fury.io/rb/quickjs)
[![Build Status](https://github.com/stefanoverna/quickjs-ruby/workflows/CI/badge.svg)](https://github.com/stefanoverna/quickjs-ruby/actions)

**QuickJS** provides a JavaScript execution environment for Ruby applications with resource controls and isolation features. Built on [QuickJS](https://bellard.org/quickjs/) by Fabrice Bellard, it offers strict memory limits, CPU timeouts, and sandboxed execution with **full ES2023 support**.

This gem is API-compatible with [mquickjs-ruby](https://github.com/stefanoverna/mquickjs-ruby) but uses the full QuickJS engine, providing modern JavaScript features.

## Security Notice

**IMPORTANT:** This gem is built on a C-based JavaScript engine and is intended as a defense-in-depth tool, not a standalone security solution.

**Use this gem ONLY if:**
- You are executing **trusted code** from known, vetted sources.
- OR you are using **additional isolation** such as Docker containers, [sandbox-runtime](https://github.com/anthropic-experimental/sandbox-runtime), gVisor, or Firecracker.

**DO NOT use this gem to execute untrusted JavaScript code in production without additional security layers.** No single library should be considered sufficient for hostile code execution. For security vulnerabilities, please email security@datocms.com.

## When to Use QuickJS (This Gem)

- You need modern JavaScript syntax (ES2023).
- You want to run existing JavaScript libraries.
- You need async/await and Promises.
- Memory is not extremely constrained (>300KB available).

For environments with extreme memory constraints (<300KB), consider [MicroQuickJS](https://github.com/bellard/mquickjs).

## Installation

**System Requirements:**
- Ruby 2.7 or higher
- C compiler (`gcc` or `clang`) and `make`

```bash
# Ubuntu/Debian
sudo apt-get install ruby-dev build-essential

# macOS
xcode-select --install
```

Add this line to your application's Gemfile:
```ruby
gem 'quickjs'
```

And then execute:
```bash
$ bundle install
```

## Quick Start

```ruby
require 'quickjs'

# Simple evaluation
result = QuickJS.eval("2 + 2")
puts result.value  # => 4

# Modern JavaScript features
result = QuickJS.eval(<<~JS)
  const greet = (name) => `Hello, ${name}!`;
  greet("World")
JS
puts result.value  # => "Hello, World!"

# With custom limits in a reusable sandbox
sandbox = QuickJS::Sandbox.new(
  memory_limit: 1_000_000,     # 1MB memory limit
  timeout_ms: 1000,           # 1 second timeout
  console_log_max_size: 50_000  # 50KB console output limit
)

result = sandbox.eval("1 + 1")
puts result.value # => 2
```

## Usage Guide

### Basic Execution & State

For one-off evaluations, use `QuickJS.eval`. For better performance across multiple calls, create a reusable `QuickJS::Sandbox` to maintain state.

```ruby
sandbox = QuickJS::Sandbox.new
sandbox.eval("var x = 10")
result = sandbox.eval("x * 2")
puts result.value  # => 20
```

### Passing Data to Scripts

Set global JavaScript variables from Ruby.

```ruby
sandbox = QuickJS::Sandbox.new
sandbox.set_variable("userName", "Alice")
result = sandbox.eval("`Hello, ${userName}!`")
puts result.value # => "Hello, Alice!"
```

### Resource Limits (Memory & CPU)

Protect your application from resource exhaustion with memory and CPU limits.

```ruby
sandbox = QuickJS::Sandbox.new(
  memory_limit: 1_000_000,  # 1MB
  timeout_ms: 5000         # 5 seconds
)

# Throws QuickJS::MemoryLimitError
# sandbox.eval("const arr = []; while(true) arr.push(new Array(1000))")

# Throws QuickJS::TimeoutError
# sandbox.eval("while(true) {}")
```
**Note:** QuickJS requires at least 300KB of memory to initialize.

### HTTP Requests

Enable the `fetch` API with security controls. Requests are fully asynchronous and support `await` and Promises.

```ruby
sandbox = QuickJS::Sandbox.new(
  http: {
    allowlist: ['https://api.github.com/**'], # Only allow these patterns
    block_private_ips: true,                  # Block 127.0.0.1, 10.0.0.0/8, etc.
    max_requests: 10,                         # Max requests per eval
    timeout_ms: 5000                          # Request timeout
  }
)

result = sandbox.eval(<<~JS)
  const response = await fetch('https://api.github.com/users/octocat');
  const data = await response.json();
  data.login
JS
puts result.value  # => "octocat"
```

### Error Handling

The gem raises specific exceptions for different error conditions. All exceptions provide common attributes for debugging:
- **`message`** (String): A descriptive error message.
- **`console_output`** (String): Any output captured from `console.log` before the error occurred.
- **`console_truncated?`** (Boolean): `true` if `console_output` was truncated due to `console_log_max_size`.

Additionally, JavaScript-specific errors provide a stack trace:
- **`stack`** (String): A JavaScript stack trace showing the call chain with function names and line numbers.

Here are the exception types:

- **`QuickJS::SyntaxError`**: Raised when JavaScript code contains a syntax error.
- **`QuickJS::JavascriptError`**: Raised when JavaScript code throws a runtime error (e.g., `TypeError`, `ReferenceError`, or an explicit `throw`).
- **`QuickJS::TimeoutError`**: Raised when JavaScript execution exceeds the configured `timeout_ms` limit.
- **`QuickJS::MemoryLimitError`**: Raised when JavaScript execution exceeds the configured `memory_limit`.
- **`QuickJS::HTTPBlockedError`**: Raised when a `fetch()` request is blocked by HTTP security rules (e.g., URL not in allowlist, private IP blocked).
- **`QuickJS::HTTPLimitError`**: Raised when an HTTP request limit is exceeded (e.g., `max_requests`, `max_request_size`, `max_response_size`).
- **`QuickJS::HTTPError`**: Raised when an HTTP request fails due to a network issue (e.g., connection timeout, DNS error).
## JavaScript Support

QuickJS supports the **ES2023 specification**, including modern features like `async`/`await`, Promises, `const`/`let`, arrow functions, classes, and `BigInt`. For a complete list of language features and the available standard library, please refer to the [MDN JavaScript Reference](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference).

## JavaScript — Delta Since ES5 (ES2015 → ES2023)

| ES Version        | Additions Beyond ES5                                                                                                                          | Resource                                                                                                             |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **ES2015–ES2018** | `let` / `const`, arrow functions, classes, modules, promises, `async` / `await`, destructuring, rest/spread, `Map` / `Set`, `Promise.finally` | [Recap](https://byby.dev/es2015)                                                                                     |
| **ES2019–ES2020** | `flat` / `flatMap`, `Object.fromEntries`, optional chaining (`?.`), nullish coalescing (`??`), `BigInt`, `Promise.allSettled`, `globalThis`   | [Recap](https://medium.com/@aashish.shrivastava2015/the-evolution-of-javascript-ecmascript-es6-to-es15-a1cd4d292c98) |
| **ES2021–ES2022** | Logical assignment (`&&=`, `\|\|=`, `??=`), `Promise.any`, `replaceAll`, top-level `await`, `Array.at`, `Object.hasOwn`, `Error.cause`        | [Recap](https://www.geeksforgeeks.org/javascript-versions/)                                                          |
| **ES2023**        | Immutable array methods (`toSorted`, `toReversed`, `toSpliced`), `findLast`, hashbang (`#!`), symbols in `WeakMap`                            | [Recap](https://www.explainthis.io/en/swe/es2023)                                                                    |

**Available Web APIs:**
- **`fetch`**: For making HTTP requests.
- **`URL`** & **`URLSearchParams`**: For parsing and manipulating URLs.
- **`Headers`**: For working with HTTP headers.
- **`Request`** & **`Response`**: Objects used with the `fetch` API.

**Limitations:**
- **No Browser/Node.js APIs**: The environment does not include `document`, `window`, `fs`, `path`, `setTimeout`, or `localStorage`.
- **ECMA402 (Intl)**: The Internationalization API is not supported.

## API Reference

### `QuickJS.eval(code, options = {})`
A one-shot method to execute JavaScript. Creates a temporary sandbox.
- **`options`**: `memory_limit`, `timeout_ms`, `console_log_max_size`, `http`.

### `QuickJS::Sandbox.new(options = {})`
Creates a reusable sandbox for multiple `eval` calls. Accepts the same `options` as `QuickJS.eval`.

### `sandbox.eval(code)`
Executes code within the sandbox and returns a `QuickJS::Result` object.

### `sandbox.set_variable(name, value)`
Sets a global variable in the JavaScript context.

### `QuickJS::Result`
The object returned from an `eval` call.
- **`value`**: The return value of the script, converted to a Ruby object.
- **`console_output`**: All output from `console.log`.

## Performance Optimization

1.  **Reuse Sandboxes**: Creating a `QuickJS::Sandbox` is faster than `QuickJS.eval` for repeated executions.
2.  **Batch Work**: Perform complex operations in a single `eval` call to minimize Ruby-to-JS overhead.
3.  **Tune Memory**: Set `memory_limit` to a reasonable value for your use case (minimum 300KB).

## Development

This section outlines how to set up your environment for developing the `quickjs-ruby` gem, run tests, and contribute changes. Bug reports and pull requests are welcome on GitHub at https://github.com/stefanoverna/quickjs-ruby.

### Development Setup

1.  Clone the repository.
2.  Run `bundle install`.
3.  Run `rake compile` to build the native extension.
4.  Run `rake test` to run the test suite.

### Common Rake Tasks

Here are some common Rake tasks useful during development:

-   `rake compile`: Compiles the native extension.
-   `rake clean`: Removes any temporary products or clean build artifacts.
-   `rake clobber`: Removes any generated files.
-   `rake test`: Runs the test suite.
-   `rake benchmark`: Runs all benchmarks.
-   `rake rubocop`: Runs RuboCop for code style analysis.
-   `rake rubocop:autocorrect`: Automatically corrects RuboCop offenses (safe changes).
-   `rake update_quickjs`: Updates QuickJS to the latest version from GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits
This gem is built on the excellent **QuickJS** engine by Fabrice Bellard.