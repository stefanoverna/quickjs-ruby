# frozen_string_literal: true

module QuickJS
  # JavaScript polyfills for the Fetch API
  # These provide standard Headers, Request, and Response classes
  module FetchPolyfill
    POLYFILLS_DIR = File.expand_path("../../../polyfills", __dir__)

    HEADERS_CLASS = File.read(File.join(POLYFILLS_DIR, "headers.js"))

    RESPONSE_CLASS = File.read(File.join(POLYFILLS_DIR, "response.js"))

    REQUEST_CLASS = File.read(File.join(POLYFILLS_DIR, "request.js"))

    FETCH_WRAPPER = File.read(File.join(POLYFILLS_DIR, "fetch_wrapper.js"))

    # Combined polyfill in correct dependency order
    FULL_POLYFILL = [
      HEADERS_CLASS,
      RESPONSE_CLASS,
      REQUEST_CLASS,
      FETCH_WRAPPER
    ].join("\n")
  end
end
