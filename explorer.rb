#!/usr/bin/env ruby
# frozen_string_literal: true

# JavaScript API Explorer for QuickJS
#
# This script explores and documents what JavaScript features are available,
# limited, or missing in QuickJS. Run it to see a comprehensive report.
#
# Usage: ruby -Ilib test/javascript_api_explorer.rb

require "quickjs"

def test(description)
  result = yield
  puts "  \u2713 #{description}: #{result.inspect}"
  result
rescue => e
  puts "  \u2717 #{description}: #{e.class.name.split('::').last} - #{e.message.lines.first&.strip}"
  nil
end

def section(title)
  puts "\n#{'=' * 70}"
  puts title
  puts '=' * 70
end

def subsection(title)
  puts "\n--- #{title} ---"
end

sandbox = QuickJS::Sandbox.new

# ============================================================================
section "DATE API"
# ============================================================================

subsection "Working"
test("Date.now()") { QuickJS.eval("Date.now()").value }
test("typeof Date") { QuickJS.eval("typeof Date").value }

subsection "NOT Working (only Date.now() is supported)"
test("new Date()") { QuickJS.eval("new Date()").value }
test("new Date(2024, 0, 15)") { QuickJS.eval("new Date(2024, 0, 15)").value }
test("new Date('2024-01-15')") { QuickJS.eval("new Date('2024-01-15')").value }
test("new Date().getFullYear()") { QuickJS.eval("new Date().getFullYear()").value }
test("new Date().toISOString()") { QuickJS.eval("new Date().toISOString()").value }

# ============================================================================
section "ES6+ SYNTAX"
# ============================================================================

subsection "NOT Supported"
test("let x = 1") { QuickJS.eval("let x = 1").value }
test("const x = 1") { QuickJS.eval("const x = 1").value }
test("arrow function: x => x * 2") { QuickJS.eval("[1,2,3].map(x => x * 2)").value }
test("template literal: `${x}`") { QuickJS.eval('var x = "hi"; `value: ${x}`').value }
test("destructuring: {a, b} = obj") { QuickJS.eval("var {a, b} = {a: 1, b: 2}").value }
test("array destructuring: [x, y] = arr") { QuickJS.eval("var [x, y] = [1, 2]").value }
test("spread: [...arr]") { QuickJS.eval("var x = [...[1,2,3]]").value }
test("object spread: {...obj}") { QuickJS.eval("var x = {...{a: 1}}").value }
test("class Foo {}") { QuickJS.eval("class Foo {}").value }
test("async function") { QuickJS.eval("async function foo() {}").value }
test("generator function*") { QuickJS.eval("function* gen() { yield 1; }").value }

subsection "Supported (ES5 syntax)"
test("var x = 1") { QuickJS.eval("var x = 1; x").value }
test("function expression") { QuickJS.eval("var f = function(x) { return x * 2; }; f(5)").value }
test("for loop") { QuickJS.eval("var sum = 0; for (var i = 0; i < 5; i++) sum += i; sum").value }
test("while loop") { QuickJS.eval("var x = 0; while (x < 3) x++; x").value }
test("for...of (arrays only)") { QuickJS.eval("var sum = 0; for (var x of [1,2,3]) sum += x; sum").value }

# ============================================================================
section "ARRAYS"
# ============================================================================

subsection "Holes NOT Allowed"
test("Array literal with hole: [1, , 3]") { QuickJS.eval("[1, , 3]").value }

subsection "new Array(n) initializes with undefined (not holes)"
test("new Array(3)") { QuickJS.eval("var a = new Array(3); JSON.stringify(a)").value }

subsection "Available Array Methods"
%w[map filter reduce forEach every some indexOf lastIndexOf
   push pop shift unshift slice splice concat join reverse sort].each do |m|
  test("Array.prototype.#{m}") { QuickJS.eval("typeof [].#{m}").value }
end
test("Array.isArray") { QuickJS.eval("typeof Array.isArray").value }

subsection "Missing Array Methods (ES6+)"
%w[find findIndex includes flat flatMap fill copyWithin entries keys values at].each do |m|
  test("Array.prototype.#{m}") { QuickJS.eval("typeof [].#{m}").value }
end
%w[from of].each do |m|
  test("Array.#{m}") { QuickJS.eval("typeof Array.#{m}").value }
end

# ============================================================================
section "STRINGS"
# ============================================================================

subsection "Available String Methods"
%w[charAt charCodeAt codePointAt slice substring concat indexOf lastIndexOf
   match replace replaceAll search split toLowerCase toUpperCase trim trimStart trimEnd].each do |m|
  test("String.prototype.#{m}") { QuickJS.eval("typeof ''.#{m}").value }
end
test("String.fromCharCode") { QuickJS.eval("typeof String.fromCharCode").value }
test("String.fromCodePoint") { QuickJS.eval("typeof String.fromCodePoint").value }

subsection "Missing String Methods (ES6+)"
%w[includes startsWith endsWith repeat padStart padEnd normalize at matchAll].each do |m|
  test("String.prototype.#{m}") { QuickJS.eval("typeof ''.#{m}").value }
end

subsection "Unicode Case Folding (ASCII-ONLY!)"
test("'hello'.toUpperCase()") { QuickJS.eval("'hello'.toUpperCase()").value }
test("'café'.toUpperCase() - é NOT converted") { QuickJS.eval("'caf\\u00e9'.toUpperCase()").value }
test("'MÜNCHEN'.toLowerCase() - Ü NOT converted") { QuickJS.eval("'M\\u00dcNCHEN'.toLowerCase()").value }

# ============================================================================
section "OBJECTS"
# ============================================================================

subsection "Available Object Methods"
%w[keys defineProperty create getPrototypeOf setPrototypeOf].each do |m|
  test("Object.#{m}") { QuickJS.eval("typeof Object.#{m}").value }
end
test("Object.prototype.hasOwnProperty") { QuickJS.eval("typeof Object.prototype.hasOwnProperty").value }

subsection "Missing Object Methods"
%w[values entries assign freeze seal isFrozen isSealed isExtensible
   preventExtensions fromEntries getOwnPropertyNames getOwnPropertyDescriptor].each do |m|
  test("Object.#{m}") { QuickJS.eval("typeof Object.#{m}").value }
end

# ============================================================================
section "NUMBERS"
# ============================================================================

subsection "Available Number Methods"
%w[toExponential toFixed toPrecision toString].each do |m|
  test("Number.prototype.#{m}") { QuickJS.eval("typeof (1).#{m}").value }
end
test("Number.parseFloat") { QuickJS.eval("typeof Number.parseFloat").value }
test("Number.parseInt") { QuickJS.eval("typeof Number.parseInt").value }

subsection "Missing Number Static Methods"
%w[isInteger isNaN isFinite isSafeInteger].each do |m|
  test("Number.#{m}") { QuickJS.eval("typeof Number.#{m}").value }
end

subsection "Available Number Constants"
%w[MAX_VALUE MIN_VALUE MAX_SAFE_INTEGER MIN_SAFE_INTEGER POSITIVE_INFINITY NEGATIVE_INFINITY NaN EPSILON].each do |c|
  test("Number.#{c}") { QuickJS.eval("typeof Number.#{c}").value }
end

# ============================================================================
section "MATH"
# ============================================================================

subsection "Available Math Methods"
%w[min max abs floor ceil round sqrt sin cos tan asin acos atan atan2
   exp log pow random sign trunc log2 log10 imul clz32 fround].each do |m|
  test("Math.#{m}") { QuickJS.eval("typeof Math.#{m}").value }
end

subsection "Available Math Constants"
%w[E LN10 LN2 LOG2E LOG10E PI SQRT1_2 SQRT2].each do |c|
  test("Math.#{c}") { QuickJS.eval("typeof Math.#{c}").value }
end

subsection "Missing Math Methods (ES6+)"
%w[cbrt expm1 log1p sinh cosh tanh asinh acosh atanh hypot].each do |m|
  test("Math.#{m}") { QuickJS.eval("typeof Math.#{m}").value }
end

# ============================================================================
section "REGEXP"
# ============================================================================

subsection "Basic Operations Work"
test("/test/i.test('TEST')") { QuickJS.eval("/test/i.test('TEST')").value }
test("/test/.exec('test string')") { QuickJS.eval("/test/.exec('test string')").value }
test("/test/gi.source") { QuickJS.eval("/test/gi.source").value }
test("/test/gi.flags") { QuickJS.eval("/test/gi.flags").value }
test("lastIndex property") { QuickJS.eval("var r = /a/g; r.exec('aaa'); r.lastIndex").value }

subsection "Missing Flag Properties"
%w[global ignoreCase multiline dotAll unicode sticky].each do |p|
  test("RegExp.prototype.#{p}") { QuickJS.eval("typeof /test/.#{p}").value }
end

# ============================================================================
section "JSON"
# ============================================================================

subsection "Available Methods"
test("JSON.parse") { QuickJS.eval('JSON.parse(\'{"a": 1}\')').value }
test("JSON.stringify") { QuickJS.eval('JSON.stringify({a: 1})').value }

subsection "Quirks"
test("JSON.stringify(function) → null") { QuickJS.eval("JSON.stringify({f: function(){}})").value }
test("JSON.stringify(undefined) → omitted") { QuickJS.eval("JSON.stringify({a: undefined, b: 1})").value }
test("JSON.stringify circular → error") { QuickJS.eval("var o = {}; o.self = o; JSON.stringify(o)").value }

# ============================================================================
section "GLOBAL FUNCTIONS"
# ============================================================================

subsection "Available"
%w[parseInt parseFloat isNaN isFinite eval].each do |f|
  test(f) { QuickJS.eval("typeof #{f}").value }
end

subsection "Missing"
%w[encodeURI decodeURI encodeURIComponent decodeURIComponent escape unescape btoa atob].each do |f|
  test(f) { QuickJS.eval("typeof #{f}").value }
end

# ============================================================================
section "ES6+ BUILT-IN OBJECTS (ALL MISSING)"
# ============================================================================

%w[Symbol Map Set WeakMap WeakSet Promise Proxy Reflect].each do |obj|
  test(obj) { QuickJS.eval("typeof #{obj}").value }
end

# ============================================================================
section "VALUE BOXING (NOT SUPPORTED)"
# ============================================================================

test("new Number(1)") { QuickJS.eval("new Number(1)").value }
test("new String('hello')") { QuickJS.eval("new String('hello')").value }
test("new Boolean(true)") { QuickJS.eval("new Boolean(true)").value }

# ============================================================================
section "EVAL BEHAVIOR"
# ============================================================================

test("indirect eval: (1, eval)('1+2')") { QuickJS.eval("(1, eval)('1 + 2')").value }
test("direct eval local access") { QuickJS.eval("(function() { var local = 42; return eval('local'); })()").value }

# ============================================================================
section "STRICT MODE (ALWAYS ENFORCED)"
# ============================================================================

test("undeclared variable assignment") { QuickJS.eval("undeclaredVar = 42").value }
test("with statement") { QuickJS.eval("with({x:1}) { x }").value }

# ============================================================================
section "TYPED ARRAYS"
# ============================================================================

%w[ArrayBuffer Uint8Array Uint8ClampedArray Int8Array Uint16Array Int16Array
   Uint32Array Int32Array Float32Array Float64Array].each do |ta|
  test(ta) { QuickJS.eval("typeof #{ta}").value }
end

# ============================================================================
section "ERROR TYPES"
# ============================================================================

%w[Error TypeError ReferenceError RangeError SyntaxError URIError EvalError].each do |e|
  test(e) { QuickJS.eval("typeof #{e}").value }
end

# ============================================================================
section "FUNCTION METHODS"
# ============================================================================

test("Function.prototype.call") { QuickJS.eval("typeof Function.prototype.call").value }
test("Function.prototype.apply") { QuickJS.eval("typeof Function.prototype.apply").value }
test("Function.prototype.bind") { QuickJS.eval("typeof Function.prototype.bind").value }
test("function.length") { QuickJS.eval("(function(a, b, c) {}).length").value }
test("function.name") { QuickJS.eval("(function foo() {}).name").value }

# ============================================================================
section "SPECIAL VALUES"
# ============================================================================

test("Infinity") { QuickJS.eval("Infinity").value }
test("-Infinity") { QuickJS.eval("-Infinity").value }
test("NaN") { QuickJS.eval("isNaN(NaN)").value }
test("undefined") { QuickJS.eval("undefined").value }
test("null") { QuickJS.eval("null").value }
test("globalThis") { QuickJS.eval("typeof globalThis").value }

puts "\n" + '=' * 70
puts "EXPLORATION COMPLETE"
puts '=' * 70
