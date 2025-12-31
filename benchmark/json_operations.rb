# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/quickjs'

module Benchmarks
  class JsonOperations
    def self.run(iterations: 1000)
      puts "\n=== JSON Operations Benchmark ==="
      puts "Iterations: #{iterations}"

      sandbox = QuickJS::Sandbox.new(memory_limit: 200_000)

      Benchmark.bm(30) do |x|
        x.report("JSON.parse (simple):") do
          iterations.times do
            sandbox.eval('JSON.parse(\'{"name":"Alice","age":30}\')')
          end
        end

        x.report("JSON.parse (nested):") do
          iterations.times do
            sandbox.eval(<<~JS)
              JSON.parse('{"user":{"name":"Alice","address":{"city":"NYC","zip":"10001"},"tags":["dev","ruby"]}}')
            JS
          end
        end

        x.report("JSON.parse (array):") do
          iterations.times do
            sandbox.eval(<<~JS)
              JSON.parse('[1,2,3,4,5,6,7,8,9,10]')
            JS
          end
        end

        x.report("JSON.stringify (simple):") do
          iterations.times do
            sandbox.eval('JSON.stringify({name:"Alice",age:30})')
          end
        end

        x.report("JSON.stringify (nested):") do
          iterations.times do
            sandbox.eval(<<~JS)
              JSON.stringify({
                user: {
                  name: "Alice",
                  address: {city: "NYC", zip: "10001"},
                  tags: ["dev", "ruby"]
                }
              })
            JS
          end
        end

        x.report("JSON round-trip:") do
          iterations.times do
            sandbox.eval(<<~JS)
              var obj = {name: "Alice", age: 30, active: true};
              var json = JSON.stringify(obj);
              JSON.parse(json);
            JS
          end
        end

        x.report("JSON parse large array:") do
          (iterations / 10).times do
            sandbox.eval(<<~JS)
              var arr = [];
              for (var i = 0; i < 100; i++) {
                arr.push({id: i, value: "item" + i});
              }
              var json = JSON.stringify(arr);
              JSON.parse(json);
            JS
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  Benchmarks::JsonOperations.run
end
