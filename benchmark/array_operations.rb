# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/mquickjs'

module Benchmarks
  class ArrayOperations
    def self.run(iterations: 500)
      puts "\n=== Array Operations Benchmark ==="
      puts "Iterations: #{iterations}"

      sandbox = QuickJS::Sandbox.new(memory_limit: 200_000)

      Benchmark.bm(30) do |x|
        x.report("Array.map (100 elements):") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr = [];
              for (var i = 0; i < 100; i++) arr.push(i);
              arr.map(function(x) { return x * 2; });
            JS
          end
        end

        x.report("Array.filter (100 elements):") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr = [];
              for (var i = 0; i < 100; i++) arr.push(i);
              arr.filter(function(x) { return x % 2 === 0; });
            JS
          end
        end

        x.report("Array.reduce (100 elements):") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr = [];
              for (var i = 0; i < 100; i++) arr.push(i);
              arr.reduce(function(acc, x) { return acc + x; }, 0);
            JS
          end
        end

        x.report("Array.forEach (100 elements):") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr = [];
              for (var i = 0; i < 100; i++) arr.push(i);
              var sum = 0;
              arr.forEach(function(x) { sum += x; });
            JS
          end
        end

        x.report("Array.sort (100 elements):") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr = [];
              for (var i = 0; i < 100; i++) arr.push(Math.random());
              arr.sort(function(a, b) { return a - b; });
            JS
          end
        end

        x.report("Array.concat:") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr1 = [1,2,3,4,5];
              var arr2 = [6,7,8,9,10];
              arr1.concat(arr2);
            JS
          end
        end

        x.report("Array.slice:") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr = [1,2,3,4,5,6,7,8,9,10];
              arr.slice(2, 8);
            JS
          end
        end

        x.report("Array.join:") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr = ["hello", "world", "from", "mquickjs"];
              arr.join(" ");
            JS
          end
        end

        x.report("Array chaining:") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr = [];
              for (var i = 0; i < 50; i++) arr.push(i);
              arr
                .filter(function(x) { return x % 2 === 0; })
                .map(function(x) { return x * 3; })
                .reduce(function(acc, x) { return acc + x; }, 0);
            JS
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  Benchmarks::ArrayOperations.run
end
