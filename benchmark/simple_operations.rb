# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/mquickjs'

module Benchmarks
  class SimpleOperations
    def self.run(iterations: 1000)
      puts "\n=== Simple Operations Benchmark ==="
      puts "Iterations: #{iterations}"

      sandbox = QuickJS::Sandbox.new

      Benchmark.bm(30) do |x|
        x.report("Arithmetic (2 + 2):") do
          iterations.times { sandbox.eval("2 + 2") }
        end

        x.report("String concatenation:") do
          iterations.times { sandbox.eval("'hello' + ' ' + 'world'") }
        end

        x.report("String methods:") do
          iterations.times { sandbox.eval("'hello world'.toUpperCase()") }
        end

        x.report("Math operations:") do
          iterations.times { sandbox.eval("Math.sqrt(16) + Math.pow(2, 8)") }
        end

        x.report("Variable assignment:") do
          iterations.times { sandbox.eval("var x = 10; var y = 20; x + y") }
        end

        x.report("Function call:") do
          iterations.times do
            sandbox.eval("function add(a, b) { return a + b; } add(5, 3)")
          end
        end

        x.report("Boolean operations:") do
          iterations.times { sandbox.eval("true && false || true") }
        end

        x.report("Typeof operator:") do
          iterations.times { sandbox.eval("typeof 'hello'") }
        end
      end
    end
  end
end

if __FILE__ == $0
  Benchmarks::SimpleOperations.run
end
