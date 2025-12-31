# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/quickjs'

module Benchmarks
  class MemoryLimits
    def self.run(iterations: 100)
      puts "\n=== Memory Limits Benchmark ==="
      puts "Testing performance with different memory limits"
      puts "Iterations: #{iterations}"

      test_code = <<~JS
        var arr = [];
        for (var i = 0; i < 100; i++) {
          arr.push({
            id: i,
            name: "Item " + i,
            value: Math.random() * 100
          });
        }
        arr.map(function(item) {
          return {
            id: item.id,
            name: item.name.toUpperCase(),
            doubled: item.value * 2
          };
        });
      JS

      Benchmark.bm(30) do |x|
        x.report("500KB limit:") do
          sandbox = QuickJS::Sandbox.new(memory_limit: 500_000)
          iterations.times { sandbox.eval(test_code) }
        end

        x.report("1MB limit (default):") do
          sandbox = QuickJS::Sandbox.new(memory_limit: 1_000_000)
          iterations.times { sandbox.eval(test_code) }
        end

        x.report("2MB limit:") do
          sandbox = QuickJS::Sandbox.new(memory_limit: 2_000_000)
          iterations.times { sandbox.eval(test_code) }
        end

        x.report("5MB limit:") do
          sandbox = QuickJS::Sandbox.new(memory_limit: 5_000_000)
          iterations.times { sandbox.eval(test_code) }
        end

        x.report("10MB limit:") do
          sandbox = QuickJS::Sandbox.new(memory_limit: 10_000_000)
          iterations.times { sandbox.eval(test_code) }
        end
      end

      # Test memory limit enforcement
      puts "\n  Memory Limit Enforcement Test:"

      memory_hungry_code = <<~JS
        var arr = [];
        for (var i = 0; i < 10000; i++) {
          arr.push(new Array(100).fill(i));
        }
      JS

      [500_000, 1_000_000, 2_000_000, 5_000_000].each do |limit|
        sandbox = QuickJS::Sandbox.new(memory_limit: limit)
        begin
          result = sandbox.eval(memory_hungry_code)
          puts "  #{limit} bytes: Success"
        rescue QuickJS::Error => e
          puts "  #{limit} bytes: #{e.class.name.split('::').last} (as expected)"
        end
      end
    end
  end
end

if __FILE__ == $0
  Benchmarks::MemoryLimits.run
end
