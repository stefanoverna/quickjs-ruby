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
