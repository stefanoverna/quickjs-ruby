# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/mquickjs'

module Benchmarks
  class SandboxOverhead
    def self.run(iterations: 1000)
      puts "\n=== Sandbox Overhead Benchmark ==="
      puts "Iterations: #{iterations}"

      Benchmark.bm(30) do |x|
        x.report("Sandbox creation:") do
          iterations.times do
            QuickJS::Sandbox.new
          end
        end

        x.report("Sandbox with custom limits:") do
          iterations.times do
            QuickJS::Sandbox.new(
              memory_limit: 100_000,
              timeout_ms: 10_000,
              console_log_max_size: 20_000
            )
          end
        end

        x.report("QuickJS.eval (creates sandbox):") do
          iterations.times do
            QuickJS.eval("2 + 2")
          end
        end

        # Compare reusing sandbox vs creating new ones
        puts "\n  Comparison: Reuse vs Create New"

        x.report("  Reuse sandbox (1000 evals):") do
          sandbox = QuickJS::Sandbox.new
          1000.times { sandbox.eval("2 + 2") }
        end

        x.report("  New sandbox each time:") do
          1000.times { QuickJS.eval("2 + 2") }
        end
      end

      # Memory footprint test
      puts "\n  Memory Footprint Test:"
      sandboxes = []
      start_memory = memory_usage

      100.times do
        sandboxes << QuickJS::Sandbox.new
      end

      end_memory = memory_usage
      memory_per_sandbox = (end_memory - start_memory) / 100.0

      puts "  100 sandboxes created"
      puts "  Memory increase: #{end_memory - start_memory} KB"
      puts "  Per sandbox: ~#{memory_per_sandbox.round(2)} KB"
    end

    def self.memory_usage
      # Get memory usage in KB (works on Linux)
      if File.exist?("/proc/self/status")
        File.read("/proc/self/status").match(/VmRSS:\s+(\d+)/)[1].to_i
      else
        0
      end
    rescue
      0
    end
  end
end

if __FILE__ == $0
  Benchmarks::SandboxOverhead.run
end
