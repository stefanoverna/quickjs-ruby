# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/mquickjs'

module Benchmarks
  class Computation
    def self.run(iterations: 100)
      puts "\n=== Computation Benchmark ==="
      puts "Iterations: #{iterations}"

      sandbox = QuickJS::Sandbox.new(memory_limit: 200_000, timeout_ms: 30_000)

      Benchmark.bm(30) do |x|
        x.report("Fibonacci (recursive, n=10):") do
          iterations.times do
            sandbox.eval(<<~JS)
              function fib(n) {
                if (n <= 1) return n;
                return fib(n - 1) + fib(n - 2);
              }
              fib(10);
            JS
          end
        end

        x.report("Fibonacci (recursive, n=15):") do
          (iterations / 2).times do
            sandbox.eval(<<~JS)
              function fib(n) {
                if (n <= 1) return n;
                return fib(n - 1) + fib(n - 2);
              }
              fib(15);
            JS
          end
        end

        x.report("Fibonacci (iterative, n=30):") do
          iterations.times do
            sandbox.eval(<<~JS)
              function fib(n) {
                var a = 0, b = 1, temp;
                for (var i = 0; i < n; i++) {
                  temp = a + b;
                  a = b;
                  b = temp;
                }
                return a;
              }
              fib(30);
            JS
          end
        end

        x.report("Factorial (n=20):") do
          iterations.times do
            sandbox.eval(<<~JS)
              function factorial(n) {
                if (n <= 1) return 1;
                return n * factorial(n - 1);
              }
              factorial(20);
            JS
          end
        end

        x.report("Array sum (1000 elements):") do
          iterations.times do
            sandbox.eval(<<~JS)
              var arr = [];
              for (var i = 0; i < 1000; i++) {
                arr.push(i);
              }
              var sum = 0;
              for (var i = 0; i < arr.length; i++) {
                sum += arr[i];
              }
              sum;
            JS
          end
        end

        x.report("Prime check (n=1000):") do
          (iterations / 2).times do
            sandbox.eval(<<~JS)
              function isPrime(n) {
                if (n <= 1) return false;
                if (n <= 3) return true;
                if (n % 2 === 0 || n % 3 === 0) return false;
                for (var i = 5; i * i <= n; i += 6) {
                  if (n % i === 0 || n % (i + 2) === 0) return false;
                }
                return true;
              }
              isPrime(1009);
            JS
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  Benchmarks::Computation.run
end
