# frozen_string_literal: true

module QuickJS
  # Base error class for all QuickJS errors
  class Error < StandardError; end

  # Raised when JavaScript code has a syntax error
  class SyntaxError < Error
    attr_reader :stack, :console_output

    def initialize(message, stack = nil, console_output = nil, console_truncated = false)
      super(message)
      @stack = stack
      @console_output = console_output || ""
      @console_truncated = console_truncated
    end

    def console_truncated?
      @console_truncated
    end
  end

  # Raised when JavaScript code throws an error
  class JavascriptError < Error
    attr_reader :stack, :console_output

    def initialize(message, stack = nil, console_output = nil, console_truncated = false)
      super(message)
      @stack = stack
      @console_output = console_output || ""
      @console_truncated = console_truncated
    end

    def console_truncated?
      @console_truncated
    end
  end

  # Raised when memory limit is exceeded
  class MemoryLimitError < Error
    attr_reader :console_output

    def initialize(message = "Memory limit exceeded", console_output = nil, console_truncated = false)
      super(message)
      @console_output = console_output || ""
      @console_truncated = console_truncated
    end

    def console_truncated?
      @console_truncated
    end
  end

  # Raised when execution timeout is exceeded
  class TimeoutError < Error
    attr_reader :console_output

    def initialize(message = "JavaScript execution timeout exceeded",
                   console_output = nil, console_truncated = false)
      super(message)
      @console_output = console_output || ""
      @console_truncated = console_truncated
    end

    def console_truncated?
      @console_truncated
    end
  end

  # Raised when HTTP request is blocked by allowlist/denylist
  class HTTPBlockedError < Error
    attr_reader :console_output

    def initialize(message, console_output = nil, console_truncated = false)
      super(message)
      @console_output = console_output || ""
      @console_truncated = console_truncated
    end

    def console_truncated?
      @console_truncated
    end
  end

  # Raised when HTTP request limit is exceeded
  class HTTPLimitError < Error
    attr_reader :console_output

    def initialize(message, console_output = nil, console_truncated = false)
      super(message)
      @console_output = console_output || ""
      @console_truncated = console_truncated
    end

    def console_truncated?
      @console_truncated
    end
  end

  # Raised when HTTP request fails
  class HTTPError < Error
    attr_reader :console_output

    def initialize(message, console_output = nil, console_truncated = false)
      super(message)
      @console_output = console_output || ""
      @console_truncated = console_truncated
    end

    def console_truncated?
      @console_truncated
    end
  end

  # Raised when invalid arguments are passed
  class ArgumentError < Error; end
end
