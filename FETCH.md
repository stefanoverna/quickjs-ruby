# Implementing Fetch Like txiki.js

This document analyzes how [txiki.js](https://github.com/saghul/txiki.js) implements the Fetch API and proposes how to apply the same approach to quickjs-ruby.

## txiki.js Architecture Overview

txiki.js is a JavaScript runtime built on:
- **QuickJS-ng** - JavaScript engine (fork of QuickJS)
- **libuv** - Event loop and platform abstraction
- **libcurl** - HTTP/WebSocket client
- **wasm3** - WebAssembly engine

### How Fetch Works in txiki.js

The fetch implementation uses a **layered architecture**:

```
┌─────────────────────────────────────────────┐
│  JavaScript: fetch() API                     │
│  (src/js/polyfills/fetch/*.js)              │
├─────────────────────────────────────────────┤
│  JavaScript: XMLHttpRequest wrapper          │
│  (src/js/polyfills/xhr.js)                  │
├─────────────────────────────────────────────┤
│  C Binding: XHR implementation               │
│  (src/xhr.c)                                │
├─────────────────────────────────────────────┤
│  C: libcurl utilities                        │
│  (src/curl-utils.c)                         │
├─────────────────────────────────────────────┤
│  libcurl + libuv event loop integration     │
└─────────────────────────────────────────────┘
```

### Layer 1: curl-utils.c (Low-Level HTTP)

This layer provides:

1. **Secure curl initialization** (`tjs__curl_easy_init()`):
   - Restricts protocols to HTTP/HTTPS only
   - Enforces TLS v1.1 minimum
   - Sets proper user agent

2. **Synchronous HTTP loading** (`tjs_curl_load_http()`):
   - Simple blocking request with 5-second timeout
   - Returns status code and response body

3. **Async integration with libuv** (`tjs__get_curlm()`):
   - Uses curl's multi interface for non-blocking requests
   - Socket events routed through libuv's poll mechanism
   - Timer callbacks for request timeouts

### Layer 2: xhr.c (XHR C Binding)

The `TJSXhr` structure contains:
```c
typedef struct {
    JSContext *ctx;
    CURL *easy;              // curl handle for this request
    CURLM *curlm;            // curl multi handle (shared)
    struct curl_slist *headers;
    DynBuf response_headers;
    DynBuf response_body;
    int ready_state;
    int status;
    // ... event handlers, configuration
} TJSXhr;
```

Key features:
- Maps HTTP lifecycle to JavaScript events (onload, onerror, onprogress, etc.)
- Supports both sync (`curl_easy_perform`) and async (`curl_multi_add_handle`) modes
- Proper state machine (UNSENT → OPENED → HEADERS_RECEIVED → LOADING → DONE)

### Layer 3: xhr.js (JavaScript Wrapper)

Wraps the native C binding with:
- EventTarget integration for proper event dispatching
- Cookie jar management (via `withCredentials`)
- Payload normalization (ArrayBuffer, Blob, FormData, etc.)

### Layer 4: fetch/*.js (Fetch Polyfill)

Standard Fetch API built on XHR:
- **fetch.js** - Main function wrapping XHR in a Promise
- **request.js** - Request class with method/body validation
- **response.js** - Response class with status/body handling
- **headers.js** - Headers class for header manipulation
- **body.js** - Body mixin for text/json/arrayBuffer methods

## Current quickjs-ruby Architecture

```
┌─────────────────────────────────────────────┐
│  JavaScript: fetch() (synchronous)           │
│  (defined in quickjs_ext.c)                 │
├─────────────────────────────────────────────┤
│  C: js_fetch() → Ruby callback              │
│  (ext/quickjs/quickjs_ext.c)                │
├─────────────────────────────────────────────┤
│  Ruby: HTTPExecutor                          │
│  (lib/quickjs/http_executor.rb)             │
├─────────────────────────────────────────────┤
│  Ruby: Net::HTTP                             │
└─────────────────────────────────────────────┘
```

### Key Differences

| Aspect | txiki.js | quickjs-ruby |
|--------|----------|--------------|
| HTTP library | libcurl (C) | Net::HTTP (Ruby) |
| Async support | Yes (libuv + curl multi) | No (synchronous) |
| Event loop | libuv | None |
| Promise support | Native | N/A (sync fetch) |
| XHR available | Yes | No |

## Proposed Approach for quickjs-ruby

### Option 1: Full txiki.js Approach (libcurl in C)

Add libcurl as a dependency and implement HTTP in C:

**Pros:**
- Self-contained (no Ruby callback overhead)
- Could support async with libuv
- Closer to browser behavior

**Cons:**
- Significant complexity increase
- New C dependency (libcurl, possibly libuv)
- Build complexity on different platforms
- Ruby's Net::HTTP is already battle-tested

**Implementation steps:**
1. Add libcurl to `extconf.rb` dependencies
2. Create `curl_utils.c` with secure curl initialization
3. Implement `xhr.c` with QuickJS bindings
4. Add JavaScript polyfills for full Fetch API

### Option 2: JavaScript Polyfill Layer (Recommended)

Keep Ruby HTTP backend but add JavaScript polyfill layer:

**Pros:**
- Minimal changes to C code
- Full Fetch API compliance via JS
- Leverages existing Ruby HTTP code
- Works with current sync model

**Cons:**
- Still synchronous (no Promises)
- Slight overhead from JS polyfill

**Implementation steps:**

1. **Create JavaScript polyfill files** in `lib/quickjs/polyfills/`:

```javascript
// headers.js
class Headers {
  constructor(init) {
    this._headers = {};
    if (init) {
      Object.entries(init).forEach(([k, v]) => this.set(k, v));
    }
  }
  get(name) { return this._headers[name.toLowerCase()] || null; }
  set(name, value) { this._headers[name.toLowerCase()] = value; }
  has(name) { return name.toLowerCase() in this._headers; }
  delete(name) { delete this._headers[name.toLowerCase()]; }
  forEach(cb) { Object.entries(this._headers).forEach(([k, v]) => cb(v, k)); }
}

// response.js
class Response {
  constructor(body, init = {}) {
    this._body = body;
    this.status = init.status || 200;
    this.statusText = init.statusText || 'OK';
    this.ok = this.status >= 200 && this.status < 300;
    this.headers = new Headers(init.headers);
  }
  text() { return this._body; }
  json() { return JSON.parse(this._body); }
}

// request.js
class Request {
  constructor(input, init = {}) {
    this.url = input;
    this.method = (init.method || 'GET').toUpperCase();
    this.headers = new Headers(init.headers);
    this.body = init.body || null;
  }
}
```

2. **Modify the C `js_fetch()` to return Response-like object** that the polyfill can wrap

3. **Inject polyfills on sandbox initialization**:

```ruby
# lib/quickjs/sandbox.rb
def initialize(options = {})
  # ... existing code ...
  inject_polyfills if options.fetch(:fetch_polyfill, true)
end

def inject_polyfills
  eval(HEADERS_POLYFILL)
  eval(RESPONSE_POLYFILL)
  eval(REQUEST_POLYFILL)
end
```

### Option 3: Hybrid Approach

Use libcurl for HTTP but keep Ruby for configuration/security:

1. Add libcurl to C extension for actual HTTP
2. Keep Ruby's HTTPConfig for URL validation/security
3. C calls Ruby only for URL validation, then uses libcurl

This gives performance benefits of C-based HTTP while keeping Ruby's flexible security model.

## Recommended Path Forward

For quickjs-ruby, **Option 2 (JavaScript Polyfill Layer)** is recommended because:

1. **Minimal risk** - No new C dependencies
2. **Full API compliance** - Headers, Request, Response classes
3. **Incremental** - Can be done in stages
4. **Testable** - JavaScript polyfills are easy to test

### Implementation Roadmap

#### Phase 1: Add Response/Headers/Request classes
- Create `lib/quickjs/polyfills/` directory
- Implement Headers, Request, Response in JavaScript
- Inject on sandbox initialization
- Update tests

#### Phase 2: Add body parsing methods
- `response.json()`
- `response.text()`
- `response.arrayBuffer()` (if needed)

#### Phase 3: Consider async (optional)
- If async is needed, evaluate adding libuv
- This is a significant undertaking

## Implementation Status

**Option 2 has been implemented.** The following files were added/modified:

### New Files
- `lib/quickjs/fetch_polyfill.rb` - JavaScript polyfills for Headers, Request, Response
- `test/fetch_polyfill_test.rb` - Comprehensive test suite (39 tests)

### Modified Files
- `lib/quickjs.rb` - Added require for fetch_polyfill
- `lib/quickjs/sandbox.rb` - Inject polyfills on initialization
- `ext/quickjs/quickjs_ext.c` - Pass response headers from Ruby to JavaScript

### Features Implemented
- ✅ `Headers` class with case-insensitive header management
- ✅ `Response` class with `json()`, `text()`, `arrayBuffer()` methods
- ✅ `Request` class with method normalization and body handling
- ✅ Fetch wrapper returning proper Response objects
- ✅ Graceful fallback for low-memory sandboxes (< 150KB)
- ✅ Full backwards compatibility with existing code

### Usage Example

```javascript
// Now works with proper Response methods
var response = fetch('https://api.example.com/data');

// Use standard methods
var data = response.json();
console.log(data.name);

// Or access body as text
var text = response.text();

// Headers work properly
var contentType = response.headers.get('content-type');

// Create requests with Request objects
var request = new Request('https://api.example.com/users', {
  method: 'POST',
  body: JSON.stringify({ name: 'John' }),
  headers: new Headers({ 'Content-Type': 'application/json' })
});
var response = fetch(request);
```

## References

- [txiki.js source code](https://github.com/saghul/txiki.js)
- [txiki.js curl-utils.c](https://github.com/saghul/txiki.js/blob/master/src/curl-utils.c)
- [txiki.js xhr.c](https://github.com/saghul/txiki.js/blob/master/src/xhr.c)
- [txiki.js fetch polyfill](https://github.com/saghul/txiki.js/tree/master/src/js/polyfills/fetch)
- [Introducing txiki.js blog post](https://code.saghul.net/2022/02/introducing-txiki-js-a-tiny-javascript-runtime/)
- [FOSDEM 2022 talk on txiki.js](https://archive.fosdem.org/2022/schedule/event/building_a_tiny_javascript_runtime_with_quickjs/)
