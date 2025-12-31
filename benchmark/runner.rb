#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'simple_operations'
require_relative 'computation'
require_relative 'json_operations'
require_relative 'array_operations'
require_relative 'sandbox_overhead'
require_relative 'memory_limits'
require_relative 'console_output'

puts "=" * 70
puts "QuickJS Benchmark Suite"
puts "=" * 70
puts "Ruby version: #{RUBY_VERSION}"
puts "Platform: #{RUBY_PLATFORM}"
puts "=" * 70

# Run all benchmarks
Benchmarks::SimpleOperations.run
Benchmarks::Computation.run
Benchmarks::JsonOperations.run
Benchmarks::ArrayOperations.run
Benchmarks::SandboxOverhead.run
Benchmarks::MemoryLimits.run
Benchmarks::ConsoleOutput.run

puts "\n" + "=" * 70
puts "Benchmark suite completed!"
puts "=" * 70
