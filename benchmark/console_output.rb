# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/mquickjs'

module Benchmarks
  class ConsoleOutput
    def self.run(iterations: 500)
      puts "\n=== Console Output Benchmark ==="
      puts "Iterations: #{iterations}"

      sandbox = QuickJS::Sandbox.new

      Benchmark.bm(30) do |x|
        x.report("Single console.log:") do
          iterations.times do
            sandbox.eval('console.log("Hello, world!"); 42')
          end
        end

        x.report("Multiple console.log calls:") do
          iterations.times do
            sandbox.eval(<<~JS)
              console.log("Starting...");
              console.log("Processing...");
              console.log("Done!");
              42
            JS
          end
        end

        x.report("Console.log in loop:") do
          iterations.times do
            sandbox.eval(<<~JS)
              for (var i = 0; i < 10; i++) {
                console.log("Iteration " + i);
              }
            JS
          end
        end

        x.report("No console output:") do
          iterations.times do
            sandbox.eval('var x = 10; x * 2')
          end
        end

        x.report("Console.log complex objects:") do
          iterations.times do
            sandbox.eval(<<~JS)
              var obj = {name: "Alice", age: 30, active: true};
              console.log("User:", obj);
              obj
            JS
          end
        end
      end

      # Test console output limits
      puts "\n  Console Output Limit Test:"

      small_limit = QuickJS::Sandbox.new(console_log_max_size: 100)
      result = small_limit.eval(<<~JS)
        for (var i = 0; i < 100; i++) {
          console.log("This is a long message that will be repeated many times");
        }
      JS

      puts "  Small limit (100 bytes):"
      puts "    Truncated: #{result.console_truncated?}"
      puts "    Output size: #{result.console_output.bytesize} bytes"

      large_limit = QuickJS::Sandbox.new(console_log_max_size: 10_000)
      result = large_limit.eval(<<~JS)
        for (var i = 0; i < 100; i++) {
          console.log("Message " + i);
        }
      JS

      puts "  Large limit (10KB):"
      puts "    Truncated: #{result.console_truncated?}"
      puts "    Output size: #{result.console_output.bytesize} bytes"
    end
  end
end

if __FILE__ == $0
  Benchmarks::ConsoleOutput.run
end
