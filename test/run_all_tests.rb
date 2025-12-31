#!/usr/bin/env ruby
# frozen_string_literal: true

# Run all test suites

require "minitest/autorun"

# Load all test files
Dir[File.join(__dir__, "**/*_test.rb")].sort.each do |test_file|
  require test_file
end

puts "\n#{'=' * 70}"
puts "All QuickJS Tests Complete"
puts "=" * 70
