# QuickJS - JavaScript Sandbox for Ruby

[![Gem Version](https://badge.fury.io/rb/quickjs.svg)](https://badge.fury.io/rb/quickjs)
[![Build Status](https://github.com/stefanoverna/quickjs-ruby/workflows/CI/badge.svg)](https://github.com/stefanoverna/quickjs-ruby/actions)

**QuickJS** provides a JavaScript execution environment for Ruby applications with resource controls and isolation features. Built on [QuickJS](https://bellard.org/quickjs/) (a fast JavaScript engine by Fabrice Bellard), it offers strict memory limits, CPU timeouts, and sandboxed execution with **full ES2020+ support**.

This gem is compatible with the [mquickjs-ruby](https://github.com/stefanoverna/mquickjs-ruby) API but uses the full QuickJS engine instead of MicroQuickJS, providing modern JavaScript features including BigInt, const/let, arrow functions, template literals, and more.

## Security Notice

**IMPORTANT:** This gem is built on QuickJS, a JavaScript engine that may contain security vulnerabilities. The sandboxing and resource limits provided by this gem are defense-in-depth measures, not a complete security solution.

**Use this gem ONLY if:**
- You are executing **trusted code** from known, vetted sources
- OR you are using **additional isolation** such as:
  - Running inside Docker containers with restricted capabilities
  - Using security sandboxes like [sandbox-runtime](https://github.com/anthropic-experimental/sandbox-runtime)
  - Operating system-level isolation (VMs, gVisor, Firecracker, etc.)

**DO NOT use this gem to execute untrusted JavaScript code directly in production without additional security layers.** No JavaScript engine sandboxing alone should be considered sufficient for hostile code execution.

## QuickJS vs MicroQuickJS

This gem uses the **full QuickJS engine**, not MicroQuickJS. Key differences:

| Feature                  | MicroQuickJS (mquickjs gem) | QuickJS (this gem)        |
| ------------------------ | --------------------------- | ------------------------- |
| **JavaScript Support**   | ES5-ish subset              | Full ES2020+              |
| **Default Memory Limit** | 50KB                        | 1MB                       |
| **Minimum Memory**       | 10KB                        | 100KB                     |
| **Binary Size**          | Smaller (~500KB)            | Larger (~1.5MB)           |
| **Memory Footprint**     | Minimal                     | Moderate                  |

**MicroQuickJS has significant JavaScript limitations:**
- No `const`/`let`, arrow functions, template literals, destructuring, classes, etc.
- Stricter mode with additional restrictions (see [MicroQuickJS Stricter Mode](https://github.com/bellard/mquickjs?tab=readme-ov-file#stricter-mode))
- Limited subset of ES5 features (see [JavaScript Subset Reference](https://github.com/bellard/mquickjs?tab=readme-ov-file#javascript-subset-reference))

**When to use QuickJS (this gem):**
- You need modern JavaScript syntax (ES2020+)
- You want to run existing JavaScript libraries
- You need async/await and Promises
- Memory is not extremely constrained (>1MB available)

**When to use MicroQuickJS:**
- Extreme memory constraints (<100KB)
- Only need basic JavaScript operations
- Want smallest possible footprint
- Targeting embedded systems

## Table of Contents

- [Security Notice](#security-notice)
- [QuickJS vs MicroQuickJS](#quickjs-vs-microquickjs)
- [Table of Contents](#table-of-contents)
- [Features](#features)
  - [Defense-in-Depth Features](#defense-in-depth-features)
  - [Production-Ready](#production-ready)
- [Installation](#installation)
  - [System Requirements](#system-requirements)
  - [From Source](#from-source)
    - [How the Build Works](#how-the-build-works)
- [Quick Start](#quick-start)
- [Usage Guide](#usage-guide)
  - [Basic Execution](#basic-execution)
  - [Modern JavaScript Features](#modern-javascript-features)
  - [Passing Data to Scripts](#passing-data-to-scripts)
  - [Memory \& CPU Limits](#memory--cpu-limits)
  - [Console Output](#console-output)
  - [HTTP Requests](#http-requests)
    - [HTTP Configuration Options](#http-configuration-options)
    - [Response Properties](#response-properties)
- [JavaScript Support](#javascript-support)
  - [Supported Features (ES2020+)](#supported-features-es2020)
  - [Available Standard Library](#available-standard-library)
  - [Limitations](#limitations)
- [Security Guardrails](#security-guardrails)
  - [Memory Safety](#memory-safety)
  - [CPU Protection](#cpu-protection)
  - [Console Output Limits](#console-output-limits)
  - [HTTP Security](#http-security)
  - [Sandboxing](#sandboxing)
  - [Error Handling](#error-handling)
    - [QuickJS::SyntaxError](#quickjssyntaxerror)
    - [QuickJS::JavascriptError](#quickjsjavascripterror)
    - [QuickJS::TimeoutError](#quickjstimeouterror)
    - [QuickJS::MemoryLimitError](#quickjsmemorylimiterror)
    - [QuickJS::HTTPBlockedError](#quickjshttpblockederror)
    - [QuickJS::HTTPLimitError](#quickjshttplimiterror)
    - [QuickJS::HTTPError](#quickjshttperror)
- [API Reference](#api-reference)
  - [QuickJS.eval(code, options = {})](#quickjsevalcode-options--)
  - [QuickJS::Sandbox.new(options = {})](#quickjssandboxnewoptions--)
  - [Sandbox#eval(code)](#sandboxevalcode)
  - [Sandbox#set\_variable(name, value)](#sandboxset_variablename-value)
  - [QuickJS::Result](#quickjsresult)
- [Performance](#performance)
  - [Running Benchmarks](#running-benchmarks)
  - [Performance Characteristics](#performance-characteristics)
  - [Optimization Tips](#optimization-tips)
- [Contributing](#contributing)
  - [Development Setup](#development-setup)
  - [Running Tests](#running-tests)
  - [Development Workflow](#development-workflow)
- [License](#license)
- [Credits](#credits)
- [Security Recommendations](#security-recommendations)
  - [When to Use Additional Isolation](#when-to-use-additional-isolation)
  - [Threat Model](#threat-model)
  - [Reporting Security Issues](#reporting-security-issues)

## Features

### Defense-in-Depth Features

- **Strict Memory Limits** - Fixed memory allocation, no dynamic growth (1MB default)
- **CPU Timeout Enforcement** - Configurable execution time limits
- **Sandboxed Execution** - Isolated from file system and network (within the JavaScript engine)
- **Console Output Limits** - Prevent memory exhaustion via console.log
- **HTTP Security Controls** - Allowlist/denylist, rate limiting, IP blocking
- **No Dangerous APIs** - No arbitrary file I/O or process access
- **Full ES2020+ Support** - Modern JavaScript features including BigInt, const/let, arrow functions
- **Async/Await & Promises** - Full Promise support with automatic resolution

### Production-Ready

- **Native C Extension** - High performance with minimal overhead
- **Zero Runtime Dependencies** - Pure Ruby + C, no external services
- **Comprehensive Test Coverage** - 95%+ tests passing
- **Thread-Safe** - Safe for concurrent execution
- **API Compatible** - Drop-in replacement for mquickjs-ruby (with updated memory limits)

## Installation

### System Requirements

- Ruby 2.7 or higher
- C compiler (`gcc` or `clang`)
- `make`

**Ubuntu/Debian:**
```bash
sudo apt-get install ruby-dev build-essential
```

**macOS:**
```bash
xcode-select --install
```

### From Source

**Note:** QuickJS source files are not yet included in the repository. You need to download them separately.

```bash
# Clone the repository
git clone https://github.com/stefanoverna/quickjs-ruby.git
cd quickjs-ruby

# Download QuickJS source
cd ext/quickjs/quickjs-src
curl -L https://bellard.org/quickjs/quickjs-2024-01-13.tar.xz -o quickjs.tar.xz
tar -xf quickjs.tar.xz --strip-components=1
rm quickjs.tar.xz
cd ../../..

# Build and test
bundle install
rake compile
rake test
```

See [CLAUDE.md](CLAUDE.md) for detailed build instructions.

#### How the Build Works

The native extension build process compiles the full QuickJS engine:

1. **Compile QuickJS source** - All QuickJS source files (quickjs.c, libregexp.c, libunicode.c, cutils.c, dtoa.c, quickjs-libc.c) are compiled with optimizations for your platform.

2. **Compile Ruby extension** - The Ruby wrapper (quickjs_ext.c) is compiled and linked with QuickJS to create the native extension (quickjs_native.so).

3. **Platform optimization** - The build system automatically detects your platform and applies appropriate compiler flags for optimal performance.

This ensures the JavaScript runtime is correctly compiled for your specific platform and architecture with full ES2020+ support.

## Quick Start

```ruby
require 'quickjs'

# Simple evaluation
result = QuickJS.eval("2 + 2")
puts result.value  # => 4

# Modern JavaScript features work!
result = QuickJS.eval(<<~JS)
  const greet = (name) => `Hello, ${name}!`;
  greet("World")
JS
puts result.value  # => "Hello, World!"

# With custom limits
sandbox = QuickJS::Sandbox.new(
  memory_limit: 1_000_000,     # 1MB memory limit (default)
  timeout_ms: 1000,             # 1 second timeout
  console_log_max_size: 50_000  # 50KB console output limit
)

# Run code
result = sandbox.eval(<<~JS)
  const fibonacci = (n) => {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
  };
  fibonacci(10);
JS

puts result.value           # => 55
puts result.console_output  # => (any console.log output)
```

## Usage Guide

### Basic Execution

```ruby
require 'quickjs'

# One-shot evaluation (creates sandbox, runs code, destroys sandbox)
result = QuickJS.eval("1 + 1")
puts result.value  # => 2

# Reusable sandbox (better performance for multiple evaluations)
sandbox = QuickJS::Sandbox.new
result1 = sandbox.eval("var x = 10")
result2 = sandbox.eval("x * 2")
puts result2.value  # => 20
```

### Modern JavaScript Features

QuickJS supports full ES2020+ syntax:

```ruby
# const and let
QuickJS.eval("const x = 10; let y = 20; x + y").value  # => 30

# Arrow functions
QuickJS.eval("const add = (a, b) => a + b; add(5, 3)").value  # => 8

# Template literals
QuickJS.eval('`The answer is ${40 + 2}`').value  # => "The answer is 42"

# Destructuring
QuickJS.eval(<<~JS).value
  const obj = { a: 1, b: 2 };
  const { a, b } = obj;
  a + b
JS
# => 3

# Spread operator
QuickJS.eval(<<~JS).value
  const arr = [1, 2, 3];
  const arr2 = [...arr, 4, 5];
  arr2.length
JS
# => 5

# BigInt (for large numbers)
QuickJS.eval("const big = 9007199254740991n; big + 1n").value  # => "9007199254740992"

# Promises and async/await
QuickJS.eval(<<~JS).value
  const result = await Promise.resolve(42);
  result * 2
JS
# => 84

# Promise chains
QuickJS.eval(<<~JS).value
  Promise.resolve(10)
    .then(x => x + 5)
    .then(x => x * 2)
JS
# => 30
```

### Passing Data to Scripts

```ruby
sandbox = QuickJS::Sandbox.new

# Set variables from Ruby
sandbox.set_variable("userName", "Alice")
sandbox.set_variable("userAge", 30)
sandbox.set_variable("userTags", ["admin", "verified"])

result = sandbox.eval(<<~JS)
  const greeting = `${userName} (age ${userAge})`;
  const tags = userTags.join(', ');
  `${greeting} - Tags: ${tags}`
JS

puts result.value
# => "Alice (age 30) - Tags: admin, verified"
```

### Memory & CPU Limits

```ruby
# Default limits
sandbox = QuickJS::Sandbox.new(
  memory_limit: 1_000_000,  # 1MB (default, minimum: 100KB)
  timeout_ms: 5000           # 5 seconds (default)
)

# Memory limit error
begin
  sandbox.eval("const arr = []; while(true) arr.push(new Array(1000))")
rescue QuickJS::MemoryLimitError => e
  puts "Out of memory!"
end

# Timeout error
begin
  sandbox.eval("while(true) {}")
rescue QuickJS::TimeoutError => e
  puts "Script took too long!"
end
```

**Important:** QuickJS requires **at least 100KB** to initialize (vs 10KB for MicroQuickJS). Use 1MB+ for real-world scripts.

### Console Output

```ruby
result = QuickJS.eval(<<~JS)
  console.log("Debug:", 42);
  console.log("User:", { name: "Alice", age: 30 });
  "result"
JS

puts result.value           # => "result"
puts result.console_output  # => "Debug: 42\nUser: [object Object]"
```

### HTTP Requests

Enable HTTP with security controls. The `fetch()` API is **fully async** and supports `await`, `.then()`, and `.catch()`:

```ruby
sandbox = QuickJS::Sandbox.new(
  http: {
    # Allowlist specific URLs
    allowlist: [
      'https://api.github.com/**',
      'https://jsonplaceholder.typicode.com/**'
    ],

    # Or denylist URLs
    denylist: ['https://evil.com/**'],

    # Block private IPs (prevent SSRF)
    block_private_ips: true,

    # Rate limiting
    max_requests: 10,

    # Timeouts and size limits
    timeout_ms: 5000,
    max_response_size: 1_000_000  # 1MB
  }
)

# Using async/await (recommended)
result = sandbox.eval(<<~JS)
  const response = await fetch('https://api.github.com/users/octocat');
  const data = await response.json();
  data.login
JS

puts result.value  # => "octocat"

# Using Promise chains
result = sandbox.eval(<<~JS)
  fetch('https://api.github.com/users/octocat')
    .then(response => response.json())
    .then(data => data.login)
JS

puts result.value  # => "octocat"
```

The fetch implementation includes standard Web API classes:
- `fetch()` - Returns a `Promise<Response>`
- `Response` - With `json()`, `text()`, `arrayBuffer()` methods (all return Promises)
- `Request` - For building HTTP requests
- `Headers` - For header manipulation

#### HTTP Configuration Options

```ruby
sandbox = QuickJS::Sandbox.new(
  http: {
    # URL allowlist (only these patterns allowed) - use ONE of allowlist or denylist
    allowlist: ['https://api.github.com/**', 'https://api.stripe.com/v1/**'],

    # OR URL denylist (block these patterns, allow everything else)
    # denylist: ['https://evil.com/**', 'https://*.malware.net/**'],

    # Security options
    block_private_ips: true,                    # Block private/local IPs (default: true)
    allowed_ports: [80, 443],                   # Allowed ports (default: [80, 443])
    allowed_methods: ['GET', 'POST'],           # HTTP methods allowed (default: GET, POST, PUT, DELETE, PATCH, HEAD)

    # Rate limiting
    max_requests: 10,                           # Max requests per eval (default: 10)

    # Size limits
    max_request_size: 1_048_576,                # Max request body size (default: 1MB)
    max_response_size: 1_048_576,               # Max response size (default: 1MB)

    # Timeout
    timeout_ms: 5000                            # Request timeout in ms (default: 5000)
  }
)
```

#### Response Properties

The `fetch()` function returns a Promise that resolves to a Response object following the standard [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Response), with full async/await support for modern JavaScript patterns.

**Available properties:**

| Property     | Type    | Description                                    |
| ------------ | ------- | ---------------------------------------------- |
| `status`     | Integer | HTTP status code (e.g., 200, 404, 500)         |
| `statusText` | String  | HTTP status message (e.g., "OK", "Not Found")  |
| `ok`         | Boolean | `true` if status is 200-299, `false` otherwise |
| `headers`    | Headers | Response headers object                        |

**Available methods (all return Promises):**

| Method          | Returns           | Description                  |
| --------------- | ----------------- | ---------------------------- |
| `text()`        | Promise\<String\> | Response body as text        |
| `json()`        | Promise\<Object\> | Response body parsed as JSON |
| `arrayBuffer()` | Promise\<Buffer\> | Response body as binary data |

**Example usage:**

```javascript
// Using async/await (recommended)
const response = await fetch('https://api.example.com/users');
console.log(response.status);      // 200
console.log(response.statusText);  // "OK"
console.log(response.ok);          // true

const data = await response.json();
console.log(data.users);

// Using Promise chains
fetch('https://api.example.com/users')
  .then(response => {
    console.log('Status:', response.status);
    return response.json();
  })
  .then(data => {
    console.log('Users:', data.users);
    return data;
  });

// Checking response before parsing
const response = await fetch('https://api.example.com/data');
if (response.ok) {
  const text = await response.text();
  console.log(text);
} else {
  console.error('Request failed:', response.statusText);
}
```

## JavaScript Support

QuickJS provides comprehensive ES2020+ JavaScript support, making it suitable for modern JavaScript codebases and libraries.

### Supported Features (ES2020+)

QuickJS includes full support for modern JavaScript:

**Variables and Scoping:**
- `var`, `let`, `const` declarations
- Block scoping with `let` and `const`
- Temporal dead zone enforcement

**Functions:**
- Arrow functions `() => {}`
- Default parameters `function(x = 10) {}`
- Rest parameters `function(...args) {}`
- Spread operator `...array`

**Objects and Arrays:**
- Object literals and shorthand `{x, y}`
- Computed property names `{[key]: value}`
- Destructuring `const {x, y} = obj`
- Array/object spread `[...arr]`, `{...obj}`

**Strings:**
- Template literals `` `Hello ${name}` ``
- Tagged templates
- Multi-line strings

**Classes:**
- Class declarations and expressions
- Constructor methods
- Static methods
- Inheritance with `extends`
- `super` keyword

**Async Programming:**
- Promises (`Promise`, `.then()`, `.catch()`, `.finally()`)
- `async`/`await` syntax
- Top-level await
- Promise combinators (`Promise.all`, `Promise.race`, etc.)

**Operators:**
- Optional chaining `obj?.prop`
- Nullish coalescing `value ?? default`
- Exponentiation `x ** y`

**Other ES2020+ Features:**
- `for...of` loops
- Iterators and generators
- `Map`, `Set`, `WeakMap`, `WeakSet`
- `Symbol`
- BigInt for arbitrary-precision integers
- Modules (import/export)
- Regular expressions with named groups

### Available Standard Library

QuickJS includes the complete ES2020+ standard library:

```javascript
// Math object - full support
Math.sqrt(16)
Math.random()
Math.floor(3.7)
Math.max(...[1, 2, 3])

// JSON - full support
JSON.parse('{"a":1}')
JSON.stringify({a: 1}, null, 2)

// String methods - ES2020+
"hello".toUpperCase()
"hello".padStart(10, '0')
"hello".repeat(3)
"hello".includes("ell")
"hello".startsWith("he")

// Array methods - full modern support
[1,2,3].map(x => x * 2)
[1,2,3].filter(x => x > 1)
[1,2,3].reduce((a,b) => a + b, 0)
[1,2,3].find(x => x === 2)
[1,2,3].findIndex(x => x === 2)
[1,2,3].includes(2)
Array.from('abc')

// Object methods - ES2020+
Object.keys({a:1, b:2})
Object.values({a:1, b:2})
Object.entries({a:1, b:2})
Object.assign({}, obj1, obj2)
Object.fromEntries([['a', 1]])

// Date - full support
new Date()
Date.now()
new Date('2024-01-01')

// console - full support
console.log("message")
console.error("error")
console.warn("warning")

// Global functions
parseInt("42")
parseFloat("3.14")
isNaN(NaN)
isFinite(100)

// Promise - full support
Promise.resolve(42)
Promise.reject(new Error('failed'))
Promise.all([p1, p2, p3])
Promise.race([p1, p2])

// Map and Set
const map = new Map([['key', 'value']])
const set = new Set([1, 2, 3])

// BigInt
const big = 9007199254740991n
big + 1n
```

### Limitations

While QuickJS supports nearly all ES2020+ features, there are some limitations:

**No Browser/Node.js APIs:**
- No DOM (`document`, `window`, etc.)
- No Node.js built-ins (`fs`, `path`, `process`, `Buffer`)
- No `XMLHttpRequest` (use `fetch()` instead)
- No `localStorage`, `sessionStorage`
- No `setTimeout`/`setInterval` (script execution is synchronous)
- No Web Workers or ServiceWorkers

**Module System:**
- Module `import`/`export` syntax is supported
- No dynamic `import()`
- No Node.js `require()` or CommonJS

**Platform APIs:**
- No file system access
- No network access (except via controlled `fetch()`)
- No process spawning or system commands

**Differences from Browser JavaScript:**
```javascript
// ❌ Won't work - No DOM
document.getElementById('app')

// ❌ Won't work - No timers (execution is not event-loop based)
setTimeout(() => console.log('later'), 1000)

// ❌ Won't work - No localStorage
localStorage.setItem('key', 'value')

// ❌ Won't work - No Node.js APIs
const fs = require('fs')

// ✅ Works - Use fetch() for HTTP
const response = await fetch('https://api.example.com/data')

// ✅ Works - Use Promises for async
const result = await Promise.resolve(42)

// ✅ Works - Use modern JavaScript
const data = await fetch(url).then(r => r.json())
```

## Security Guardrails

### Memory Safety

**Fixed Memory Allocation:** QuickJS is initialized with a fixed memory limit (default: 1MB, minimum: 100KB). The JavaScript heap cannot grow beyond this limit.

```ruby
sandbox = QuickJS::Sandbox.new(memory_limit: 500_000)  # 500KB

begin
  sandbox.eval("const huge = new Array(1000000)")  # Allocates too much
rescue QuickJS::MemoryLimitError => e
  puts "Memory limit exceeded"
  puts e.message  # Details about the error
end
```

### CPU Protection

**Execution Timeout:** Scripts are interrupted if they exceed the timeout.

```ruby
sandbox = QuickJS::Sandbox.new(timeout_ms: 100)  # 100ms limit

begin
  sandbox.eval("while(true) {}")  # Infinite loop
rescue QuickJS::TimeoutError => e
  puts "Script timed out"
end
```

### Console Output Limits

**Size Restriction:** Prevents memory exhaustion via console.log spam.

```ruby
sandbox = QuickJS::Sandbox.new(console_log_max_size: 1000)  # 1KB limit

result = sandbox.eval(<<~JS)
  for (let i = 0; i < 1000; i++) {
    console.log("Spam message " + i);
  }
  "done"
JS

puts result.console_output.length  # Capped at ~1KB
```

### HTTP Security

**URL Allowlist/Denylist, IP Blocking, Rate Limiting:**

```ruby
sandbox = QuickJS::Sandbox.new(
  http: {
    allowlist: ['https://api.trusted.com/**'],
    denylist: ['https://api.trusted.com/admin/**'],
    block_private_ips: true,  # Prevent SSRF to 127.0.0.1, 10.0.0.0/8, etc.
    max_requests: 5,
    timeout_ms: 3000
  }
)

# ✅ Allowed
sandbox.eval(<<~JS)
  const response = await fetch('https://api.trusted.com/users');
  await response.json()
JS

# ❌ Blocked (denylist)
begin
  sandbox.eval("fetch('https://api.trusted.com/admin/secrets')")
rescue QuickJS::HTTPBlockedError
  puts "URL blocked by denylist"
end

# ❌ Blocked (not in allowlist)
begin
  sandbox.eval("fetch('https://evil.com')")
rescue QuickJS::HTTPBlockedError
  puts "URL not in allowlist"
end

# ❌ Blocked (private IP - SSRF protection)
begin
  sandbox.eval("fetch('http://127.0.0.1:8080')")
rescue QuickJS::HTTPBlockedError
  puts "Private IP blocked"
end
```

### Sandboxing

- **No File System Access:** Cannot read/write files
- **No Network Access:** Except via controlled `fetch()` API
- **No Process Access:** Cannot spawn processes or execute system commands
- **Isolated Global Scope:** Each sandbox has its own global object

### Error Handling

QuickJS provides specific exception classes for different error types. All error objects include `console_output` and `console_truncated?` attributes to help with debugging.

```ruby
begin
  sandbox.eval(your_code)
rescue QuickJS::SyntaxError => e
  # JavaScript syntax error
  puts "Invalid syntax: #{e.message}"
  puts e.stack
rescue QuickJS::JavascriptError => e
  # JavaScript runtime error (throw, ReferenceError, etc.)
  puts "Runtime error: #{e.message}"
  puts e.stack
rescue QuickJS::MemoryLimitError => e
  # Memory limit exceeded
  puts "Out of memory: #{e.message}"
rescue QuickJS::TimeoutError => e
  # Execution timeout
  puts "Timeout: #{e.message}"
rescue QuickJS::HTTPBlockedError => e
  # HTTP request blocked by security rules
  puts "HTTP blocked: #{e.message}"
rescue QuickJS::HTTPLimitError => e
  # HTTP limit exceeded (max requests, size limits)
  puts "HTTP limit: #{e.message}"
rescue QuickJS::HTTPError => e
  # HTTP request failed
  puts "HTTP error: #{e.message}"
end
```

#### QuickJS::SyntaxError

Raised when JavaScript code contains a syntax error.

**Attributes:**
- `message` (String): The full error message, prefixed with `SyntaxError:` and a description
- `stack` (String): Location info showing where the syntax error occurred (line and column)
- `console_output` (String): Any console.log output captured before the error (typically empty for syntax errors since they occur at parse time)
- `console_truncated?` (Boolean): Whether console output was truncated due to size limits

**Example:**

```ruby
begin
  sandbox.eval("const x = 1;\nconst y = 2;\nfunction broken() {")
rescue QuickJS::SyntaxError => e
  puts e.message
  # => "SyntaxError: expecting '}'"

  puts e.stack
  # => "    at <eval>:3:20\n"

  puts e.console_output
  # => "" (syntax errors occur at parse time, before execution)
end
```

**Common syntax errors:**

```ruby
# Missing closing brace
sandbox.eval("function test() { const x = 1;")
# => SyntaxError: expecting '}'

# Invalid arrow function syntax (though QuickJS supports them)
sandbox.eval("const fn = =>")
# => SyntaxError: unexpected token

# Malformed object literal
sandbox.eval("const obj = {a: 1, b: }")
# => SyntaxError: unexpected token
```

#### QuickJS::JavascriptError

Raised when JavaScript code throws an error at runtime. This includes explicit `throw` statements and built-in errors like `TypeError`, `ReferenceError`, etc.

**Attributes:**
- `message` (String): The full error message, including the error type and description
- `stack` (String): JavaScript stack trace showing the call chain with function names and line numbers
- `console_output` (String): Any console.log output captured before the error occurred
- `console_truncated?` (Boolean): Whether console output was truncated due to size limits

**Example:**

```ruby
begin
  sandbox.eval(<<~JS)
    console.log("Processing user...");
    function processUser(user) {
      console.log("User received:", user);
      return user.name.toUpperCase();
    }
    processUser(null);  // Will throw TypeError
  JS
rescue QuickJS::JavascriptError => e
  puts e.message
  # => "TypeError: cannot read property 'name' of null"

  puts e.stack
  # => "    at processUser (<eval>:4:19)\n    at <eval> (<eval>:6:4)\n"

  puts e.console_output
  # => "Processing user...\nUser received: null\n"
  # Useful for debugging what happened before the error!
end
```

**Stack trace example with nested calls:**

```ruby
begin
  sandbox.eval(<<~JS)
    function innerFunc() {
      throw new Error("something went wrong");
    }
    function outerFunc() {
      innerFunc();
    }
    outerFunc();
  JS
rescue QuickJS::JavascriptError => e
  puts "Error: #{e.message}"
  puts "Stack trace:"
  e.stack.each_line { |line| puts "  #{line}" }
  # Error: Error: something went wrong
  # Stack trace:
  #       at innerFunc (<eval>:2:18)
  #       at outerFunc (<eval>:5:6)
  #       at <eval> (<eval>:7:4)
end
```

**Common runtime errors:**

```ruby
# Accessing undefined variable
sandbox.eval("undefinedVariable")
# => ReferenceError: variable 'undefinedVariable' is not defined

# Accessing property of null
sandbox.eval("null.foo")
# => TypeError: cannot read property 'foo' of null

# Calling non-function
sandbox.eval("const x = {}; x.foo()")
# => TypeError: not a function

# Explicit throw
sandbox.eval("throw new Error('something went wrong')")
# => Error: something went wrong
```

**Error types captured as JavascriptError:**

| JavaScript Error | Description                                                  |
| ---------------- | ------------------------------------------------------------ |
| `Error`          | Generic error from `throw new Error()`                       |
| `TypeError`      | Type mismatch (e.g., calling non-function, property of null) |
| `ReferenceError` | Accessing undefined variable                                 |
| `RangeError`     | Value out of allowed range                                   |
| `URIError`       | Malformed URI functions                                      |
| `EvalError`      | Error in eval() (rarely thrown)                              |
| `InternalError`  | Internal engine error                                        |

**Debugging tips:**

```ruby
begin
  sandbox.eval(user_code)
rescue QuickJS::JavascriptError => e
  # Parse the error type from the message
  error_type = e.message.split(':').first  # "TypeError", "ReferenceError", etc.

  case error_type
  when "TypeError"
    puts "Type error - check for null/undefined values or type mismatches"
  when "ReferenceError"
    puts "Undefined variable - check variable names and scope"
  when "RangeError"
    puts "Value out of range - check array indices or numeric values"
  else
    puts "JavaScript error: #{e.message}"
  end
end
```

**Custom error messages from JavaScript:**

```ruby
begin
  sandbox.eval(<<~JS)
    function validateAge(age) {
      if (typeof age !== 'number') {
        throw new TypeError(`age must be a number, got ${typeof age}`);
      }
      if (age < 0 || age > 150) {
        throw new RangeError(`age must be between 0 and 150, got ${age}`);
      }
      return age;
    }
    validateAge("twenty");
  JS
rescue QuickJS::JavascriptError => e
  puts e.message
  # => "TypeError: age must be a number, got string"
end
```

#### QuickJS::TimeoutError

Raised when JavaScript execution exceeds the configured timeout.

**Attributes:**
- `message` (String): The timeout error message
- `console_output` (String): Any console.log output captured before the timeout
- `console_truncated?` (Boolean): Whether console output was truncated due to size limits

**Example:**

```ruby
begin
  sandbox = QuickJS::Sandbox.new(timeout_ms: 100)
  sandbox.eval(<<~JS)
    console.log("Starting long computation...");
    console.log("This might take a while...");
    while(true) {}  // Infinite loop
  JS
rescue QuickJS::TimeoutError => e
  puts e.message
  # => "JavaScript execution timeout exceeded"

  puts e.console_output
  # => "Starting long computation...\nThis might take a while...\n"
  # See what the script was doing before it timed out
end
```

#### QuickJS::MemoryLimitError

Raised when JavaScript execution exceeds the configured memory limit.

**Attributes:**
- `message` (String): The memory limit error message
- `console_output` (String): Any console.log output captured before memory was exhausted
- `console_truncated?` (Boolean): Whether console output was truncated due to size limits

**Example:**

```ruby
begin
  sandbox = QuickJS::Sandbox.new(memory_limit: 100_000)  # 100KB
  sandbox.eval(<<~JS)
    console.log("Allocating large array...");
    const huge = new Array(1000000);  // Too large
  JS
rescue QuickJS::MemoryLimitError => e
  puts e.message
  # => "Memory limit exceeded"

  puts e.console_output
  # => "Allocating large array...\n"
end
```

#### QuickJS::HTTPBlockedError

Raised when a fetch() request is blocked by the URL allowlist/denylist configuration.

**Attributes:**
- `message` (String): Description of why the request was blocked
- `console_output` (String): Any console.log output captured before the blocked request
- `console_truncated?` (Boolean): Whether console output was truncated due to size limits

**Example:**

```ruby
sandbox = QuickJS::Sandbox.new(
  http: { allowlist: ['https://api.example.com/**'] }
)

begin
  sandbox.eval(<<~JS)
    console.log("Fetching data from external API...");
    await fetch('https://blocked-domain.com/api');
  JS
rescue QuickJS::HTTPBlockedError => e
  puts e.message
  # => "URL not in allowlist: https://blocked-domain.com/api"

  puts e.console_output
  # => "Fetching data from external API...\n"
end
```

#### QuickJS::HTTPLimitError

Raised when HTTP request limits are exceeded (max requests, request size, or response size).

**Attributes:**
- `message` (String): Description of which limit was exceeded
- `console_output` (String): Any console.log output captured before the limit was hit
- `console_truncated?` (Boolean): Whether console output was truncated due to size limits

**Example:**

```ruby
sandbox = QuickJS::Sandbox.new(
  http: {
    allowlist: ['https://api.example.com/**'],
    max_requests: 2
  }
)

begin
  sandbox.eval(<<~JS)
    await fetch('https://api.example.com/endpoint1');
    await fetch('https://api.example.com/endpoint2');
    await fetch('https://api.example.com/endpoint3');  // Too many
  JS
rescue QuickJS::HTTPLimitError => e
  puts e.message
  # => "Maximum number of HTTP requests exceeded (2)"
end
```

#### QuickJS::HTTPError

Raised when an HTTP request fails (network error, timeout, etc.).

**Attributes:**
- `message` (String): Description of the HTTP failure
- `console_output` (String): Any console.log output captured before the failure
- `console_truncated?` (Boolean): Whether console output was truncated due to size limits

**Example:**

```ruby
sandbox = QuickJS::Sandbox.new(
  http: {
    allowlist: ['https://**'],
    timeout_ms: 1000
  }
)

begin
  sandbox.eval(<<~JS)
    // Request to a slow or non-existent server
    await fetch('https://non-existent-domain-12345.com/api');
  JS
rescue QuickJS::HTTPError => e
  puts e.message
  # => "HTTP request failed: connection timeout"
end
```

## API Reference

### QuickJS.eval(code, options = {})

One-shot JavaScript evaluation. Creates a sandbox, runs code, and destroys sandbox.

**Parameters:**
- `code` (String) - JavaScript code to execute
- `options` (Hash) - Optional configuration:
  - `memory_limit` (Integer) - Memory limit in bytes (default: 1,000,000, min: 100,000)
  - `timeout_ms` (Integer) - Timeout in milliseconds (default: 5,000)
  - `console_log_max_size` (Integer) - Console output limit (default: 10,000)
  - `http` (Hash) - HTTP configuration (see below)

**Returns:** `QuickJS::Result` object

**Example:**
```ruby
result = QuickJS.eval("2 + 2", memory_limit: 500_000, timeout_ms: 1000)
puts result.value  # => 4
```

### QuickJS::Sandbox.new(options = {})

Create a reusable JavaScript sandbox.

**Parameters:** Same as `QuickJS.eval`

**Returns:** `QuickJS::Sandbox` instance

**Example:**
```ruby
sandbox = QuickJS::Sandbox.new(
  memory_limit: 1_000_000,
  timeout_ms: 5000,
  http: { allowlist: ['https://api.example.com/**'] }
)
```

### Sandbox#eval(code)

Execute JavaScript code in the sandbox.

**Parameters:**
- `code` (String) - JavaScript code to execute

**Returns:** `QuickJS::Result` object

### Sandbox#set_variable(name, value)

Set a global variable from Ruby.

**Parameters:**
- `name` (String) - Variable name
- `value` - Ruby value (String, Integer, Float, Boolean, Array, Hash, nil)

**Example:**
```ruby
sandbox.set_variable("config", { api_key: "secret", timeout: 30 })
sandbox.eval("config.timeout")  # => 30
```

### QuickJS::Result

Returned by `eval()` calls.

**Attributes:**
- `value` - The JavaScript return value (converted to Ruby)
- `console_output` - String containing all console.log output

**Example:**
```ruby
result = QuickJS.eval('console.log("hi"); 42')
result.value           # => 42
result.console_output  # => "hi"
```

## Performance

QuickJS provides excellent performance for JavaScript execution with minimal overhead. The full ES2020+ support enables running modern JavaScript libraries efficiently.

### Running Benchmarks

The gem includes a comprehensive benchmark suite:

```bash
# Run all benchmarks
rake benchmark

# Clean and recompile before benchmarking
rake clean
rake compile
rake benchmark
```

### Performance Characteristics

**Key metrics:**
- **Sandbox creation:** ~30-50μs (reusable for multiple evaluations)
- **Simple operations:** ~1-5μs per operation (arithmetic, string operations)
- **JSON operations:** ~5-15μs per operation (parse/stringify)
- **Array operations:** ~10-30μs for 100 elements
- **Modern JS features:** Minimal overhead for const/let, arrow functions, template literals
- **Promise/async-await:** Efficient async execution with automatic promise resolution
- **Memory overhead:** Moderate (~1MB default, configurable)
- **Thread-safe:** Yes (each sandbox is independent)

**ES2020+ features performance:**
- Arrow functions: No performance penalty vs function expressions
- Template literals: Comparable to string concatenation
- Destructuring: Minimal overhead
- Promises/async-await: Efficient promise resolution

### Optimization Tips

1. **Reuse sandboxes** when possible:
   ```ruby
   # Good: Reuse sandbox
   sandbox = QuickJS::Sandbox.new
   1000.times { sandbox.eval(code) }

   # Less efficient: Create new sandbox each time
   1000.times { QuickJS.eval(code) }
   ```

2. **Batch operations** in JavaScript when possible:
   ```ruby
   # More efficient: Process array in JavaScript
   sandbox.eval('[1,2,3,4,5].map(x => x * 2)')

   # Less efficient: Multiple Ruby calls
   [1,2,3,4,5].map { |x| sandbox.eval("#{x} * 2").value }
   ```

3. **Use appropriate memory limits:**
   ```ruby
   # Small scripts: use minimal memory
   QuickJS::Sandbox.new(memory_limit: 100_000)  # 100KB

   # Complex operations: allocate more
   QuickJS::Sandbox.new(memory_limit: 5_000_000)  # 5MB
   ```

4. **Leverage modern JavaScript:**
   ```ruby
   # Use modern syntax for cleaner, more maintainable code
   sandbox.eval(<<~JS)
     const data = await fetch(url).then(r => r.json());
     const results = data.items
       .filter(item => item.active)
       .map(item => ({ id: item.id, name: item.name }));
     return results;
   JS
   ```

5. **Pre-compile reusable code:**
   ```ruby
   # Set up functions once, use multiple times
   sandbox.eval(<<~JS)
     function processUser(user) {
       return {
         fullName: `${user.firstName} ${user.lastName}`,
         age: new Date().getFullYear() - user.birthYear
       };
     }
   JS

   # Then call it with different data
   sandbox.set_variable('user', { firstName: 'Alice', lastName: 'Smith', birthYear: 1990 })
   result1 = sandbox.eval('processUser(user)')

   sandbox.set_variable('user', { firstName: 'Bob', lastName: 'Jones', birthYear: 1985 })
   result2 = sandbox.eval('processUser(user)')
   ```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stefanoverna/quickjs-ruby.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/stefanoverna/quickjs-ruby.git
cd quickjs-ruby

# Download QuickJS source (if not already present)
# See Installation section above for details

# Install dependencies
bundle install

# Build the extension
rake compile
```

### Running Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test file
ruby -Ilib test/quickjs_test.rb

# Run with verbose output
ruby -Ilib test/quickjs_test.rb --verbose
```

### Development Workflow

```bash
# Clean previous builds
rake clean

# Recompile
rake compile

# Run tests
rake test

# Run benchmarks
rake benchmark

# Update QuickJS to a new version
rake update_quickjs
```

See [UPDATING_QUICKJS.md](UPDATING_QUICKJS.md) for information on updating to newer QuickJS versions.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

- **QuickJS**: Created by Fabrice Bellard - https://bellard.org/quickjs/
- A fast, small, and embeddable JavaScript engine with ES2020+ support

## Security Recommendations

### When to Use Additional Isolation

For untrusted code execution, **always** use additional security layers beyond this gem:

**Option 1: Docker Containers**
```bash
# Run with restricted capabilities and no network
docker run --rm --cap-drop=ALL --network=none \
  -v $(pwd):/app ruby:3.3 \
  ruby /app/your_script.rb
```

**Option 2: Anthropic Sandbox Runtime**
- [sandbox-runtime](https://github.com/anthropic-experimental/sandbox-runtime) provides secure Python/JavaScript sandboxing
- Designed specifically for LLM-generated code execution

**Option 3: VM-based Isolation**
- gVisor for lightweight VM isolation
- Firecracker for microVM isolation
- Traditional VMs for maximum isolation

### Threat Model

**What this gem protects against:**
- Accidental infinite loops (via timeout)
- Memory exhaustion (via memory limits)
- Excessive console output
- Basic SSRF attempts (via HTTP allowlist/denylist and IP blocking)

**What this gem does NOT protect against:**
- JavaScript engine vulnerabilities (RCE, sandbox escapes)
- Side-channel attacks
- Timing attacks
- CPU-based DoS (partially mitigated by timeout)
- All classes of sophisticated attacks

**Security philosophy:**
This gem provides defense-in-depth resource controls and isolation within the JavaScript engine. These controls are valuable for:
- Preventing accidental resource exhaustion
- Basic protection against simple attacks
- Running code from trusted sources with resource constraints

However, **do not rely on this gem alone** for executing untrusted code. Always use additional OS-level or container-based isolation for hostile code execution.

### Reporting Security Issues

For security vulnerabilities in this gem, please email security@datocms.com instead of using the issue tracker.
