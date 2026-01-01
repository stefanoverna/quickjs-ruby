# frozen_string_literal: true

module QuickJS
  # JavaScript polyfills for the Fetch API
  # These provide standard Headers, Request, and Response classes
  module FetchPolyfill
    HEADERS_CLASS = <<~JS
      (function() {
        if (typeof Headers !== 'undefined') return;

        globalThis.Headers = class Headers {
          constructor(init) {
            this._headers = {};

            if (init) {
              if (init instanceof Headers) {
                init.forEach((value, name) => this.append(name, value));
              } else if (Array.isArray(init)) {
                init.forEach(([name, value]) => this.append(name, value));
              } else if (typeof init === 'object') {
                Object.entries(init).forEach(([name, value]) => this.append(name, value));
              }
            }
          }

          append(name, value) {
            const key = name.toLowerCase();
            if (this._headers[key]) {
              this._headers[key] += ', ' + value;
            } else {
              this._headers[key] = String(value);
            }
          }

          delete(name) {
            delete this._headers[name.toLowerCase()];
          }

          get(name) {
            return this._headers[name.toLowerCase()] || null;
          }

          has(name) {
            return name.toLowerCase() in this._headers;
          }

          set(name, value) {
            this._headers[name.toLowerCase()] = String(value);
          }

          forEach(callback, thisArg) {
            Object.entries(this._headers).forEach(([name, value]) => {
              callback.call(thisArg, value, name, this);
            });
          }

          keys() {
            return Object.keys(this._headers)[Symbol.iterator]();
          }

          values() {
            return Object.values(this._headers)[Symbol.iterator]();
          }

          entries() {
            return Object.entries(this._headers)[Symbol.iterator]();
          }

          [Symbol.iterator]() {
            return this.entries();
          }
        };
      })();
    JS

    RESPONSE_CLASS = <<~JS
      (function() {
        if (typeof Response !== 'undefined') return;

        globalThis.Response = class Response {
          constructor(body, init = {}) {
            this._body = body !== undefined && body !== null ? String(body) : '';
            this._bodyUsed = false;

            this.status = init.status !== undefined ? init.status : 200;
            this.statusText = init.statusText !== undefined ? init.statusText : '';
            this.ok = this.status >= 200 && this.status < 300;
            this.headers = init.headers instanceof Headers
              ? init.headers
              : new Headers(init.headers);
            this.type = init.type || 'default';
            this.url = init.url || '';
            this.redirected = init.redirected || false;
          }

          get bodyUsed() {
            return this._bodyUsed;
          }

          // For backwards compatibility with existing code that accesses .body directly
          get body() {
            return this._body;
          }

          clone() {
            if (this._bodyUsed) {
              throw new TypeError('Cannot clone a Response whose body has been used');
            }
            return new Response(this._body, {
              status: this.status,
              statusText: this.statusText,
              headers: new Headers(this.headers),
              type: this.type,
              url: this.url,
              redirected: this.redirected
            });
          }

          text() {
            if (this._bodyUsed) {
              return Promise.reject(new TypeError('Body has already been consumed'));
            }
            this._bodyUsed = true;
            return Promise.resolve(this._body);
          }

          json() {
            if (this._bodyUsed) {
              return Promise.reject(new TypeError('Body has already been consumed'));
            }
            this._bodyUsed = true;
            try {
              return Promise.resolve(JSON.parse(this._body));
            } catch (e) {
              return Promise.reject(e);
            }
          }

          arrayBuffer() {
            if (this._bodyUsed) {
              return Promise.reject(new TypeError('Body has already been consumed'));
            }
            this._bodyUsed = true;
            // Simple implementation - convert string to array of char codes
            var body = this._body;
            var buf = new ArrayBuffer(body.length);
            var view = new Uint8Array(buf);
            for (var i = 0; i < body.length; i++) {
              view[i] = body.charCodeAt(i) & 0xff;
            }
            return Promise.resolve(buf);
          }

          blob() {
            return Promise.reject(new TypeError('Blob is not supported in this environment'));
          }

          formData() {
            return Promise.reject(new TypeError('FormData is not supported in this environment'));
          }

          static error() {
            var response = new Response(null, { status: 0, statusText: '' });
            response.type = 'error';
            return response;
          }

          static redirect(url, status) {
            if (status === undefined) status = 302;
            if ([301, 302, 303, 307, 308].indexOf(status) === -1) {
              throw new RangeError('Invalid redirect status code');
            }
            return new Response(null, {
              status: status,
              headers: { 'Location': url }
            });
          }
        };
      })();
    JS

    REQUEST_CLASS = <<~JS
      (function() {
        if (typeof Request !== 'undefined') return;

        var validMethods = ['DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT'];

        function normalizeMethod(method) {
          var upper = method.toUpperCase();
          if (validMethods.indexOf(upper) !== -1) {
            return upper;
          }
          return method;
        }

        globalThis.Request = class Request {
          constructor(input, init = {}) {
            if (input instanceof Request) {
              this.url = input.url;
              this.method = input.method;
              this.headers = new Headers(input.headers);
              this._body = input._body;
              this.credentials = input.credentials;
              this.mode = input.mode;
              this.cache = input.cache;
              this.redirect = input.redirect;
              this.referrer = input.referrer;
              this.integrity = input.integrity;
            } else {
              this.url = String(input);
              this.method = 'GET';
              this.headers = new Headers();
              this._body = null;
              this.credentials = 'same-origin';
              this.mode = 'cors';
              this.cache = 'default';
              this.redirect = 'follow';
              this.referrer = 'about:client';
              this.integrity = '';
            }

            // Apply init options
            if (init.method !== undefined) {
              this.method = normalizeMethod(init.method);
            }
            if (init.headers !== undefined) {
              this.headers = init.headers instanceof Headers
                ? init.headers
                : new Headers(init.headers);
            }
            if (init.body !== undefined && init.body !== null) {
              if (this.method === 'GET' || this.method === 'HEAD') {
                throw new TypeError('Request with GET/HEAD method cannot have body');
              }
              this._body = String(init.body);
            }
            if (init.credentials !== undefined) {
              this.credentials = init.credentials;
            }
            if (init.mode !== undefined) {
              this.mode = init.mode;
            }
            if (init.cache !== undefined) {
              this.cache = init.cache;
            }
            if (init.redirect !== undefined) {
              this.redirect = init.redirect;
            }
            if (init.referrer !== undefined) {
              this.referrer = init.referrer;
            }
            if (init.integrity !== undefined) {
              this.integrity = init.integrity;
            }
          }

          get body() {
            return this._body;
          }

          clone() {
            return new Request(this);
          }

          text() {
            return Promise.resolve(this._body || '');
          }

          json() {
            try {
              return Promise.resolve(JSON.parse(this._body || 'null'));
            } catch (e) {
              return Promise.reject(e);
            }
          }
        };
      })();
    JS

    FETCH_WRAPPER = <<~JS
      (function() {
        // Store reference to native fetch
        var nativeFetch = globalThis.fetch;

        if (!nativeFetch) {
          // No native fetch available
          return;
        }

        // Wrap native fetch to return a Promise with proper Response objects
        globalThis.fetch = function fetch(input, init) {
          return new Promise(function(resolve, reject) {
            // Validate input - must be provided
            if (input === undefined) {
              reject(new TypeError('fetch() requires at least 1 argument (url)'));
              return;
            }

            try {
              var url, options = {};

              // Handle Request object as input
              if (input instanceof Request) {
                url = input.url;
                options.method = input.method;
                if (input._body) {
                  options.body = input._body;
                }
                // Copy headers from Request
                var headerObj = {};
                input.headers.forEach(function(value, name) {
                  headerObj[name] = value;
                });
                if (Object.keys(headerObj).length > 0) {
                  options.headers = headerObj;
                }
              } else {
                url = String(input);
              }

              // Merge init options (overrides Request properties)
              if (init) {
                if (init.method !== undefined) {
                  options.method = init.method;
                }
                if (init.body !== undefined) {
                  options.body = init.body;
                }
                if (init.headers !== undefined) {
                  if (init.headers instanceof Headers) {
                    var headerObj = {};
                    init.headers.forEach(function(value, name) {
                      headerObj[name] = value;
                    });
                    options.headers = headerObj;
                  } else {
                    options.headers = init.headers;
                  }
                }
              }

              // Call native fetch (synchronous, but wrapped in Promise)
              var nativeResponse = nativeFetch(url, options);

              // Convert native response to Response object
              var responseHeaders = new Headers(nativeResponse.headers || {});

              var response = new Response(nativeResponse.body, {
                status: nativeResponse.status,
                statusText: nativeResponse.statusText,
                headers: responseHeaders,
                url: url
              });

              resolve(response);
            } catch (error) {
              reject(error);
            }
          });
        };
      })();
    JS

    # Combined polyfill in correct dependency order
    FULL_POLYFILL = [
      HEADERS_CLASS,
      RESPONSE_CLASS,
      REQUEST_CLASS,
      FETCH_WRAPPER
    ].join("\n")
  end
end
