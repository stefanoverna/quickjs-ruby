#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'quickjs'

puts "Creating sandbox..."
sandbox = QuickJS::Sandbox.new
puts "Sandbox created successfully!"

puts "\nTesting simple evaluation..."
begin
  result = sandbox.eval("2 + 2")
  puts "Result value: #{result.value}"
  puts "Console output: #{result.console_output.inspect}"
rescue => e
  puts "Error: #{e.class}: #{e.message}"
  puts "Stacktrace:"
  puts e.backtrace.first(10).join("\n")
end

puts "\nTesting string evaluation..."
begin
  result = sandbox.eval("'hello world'")
  puts "Result value: #{result.value.inspect}"
rescue => e
  puts "Error: #{e.class}: #{e.message}"
end

puts "\nDone!"
