# TODO - QuickJS Ruby Gem

This document tracks remaining work to make quickjs-ruby production-ready.

## Critical Issues

### 1. Fix RuboCop Linting Failures
**Priority: High**
**Status: Blocked**

RuboCop linting cannot be run due to bundler/dependency issues.

**Issue:**
- `bundle install` fails with Ruby 3.3.6/Bundler 4.0.1 compatibility issue
- Error: `uninitialized class variable @@accept_charset in #<Class:CGI>`
- RuboCop gem is in Gemfile but cannot be installed

**Possible Solutions:**
- Downgrade Bundler version
- Install RuboCop system-wide
- Update gem dependencies to be compatible with Bundler 4.0
- Run RuboCop through CI (GitHub Actions) which has working setup

---

## Enhancements

### 2. Add Benchmarks
**Priority: Low**
**Status: Not Started**

The `benchmark/` directory exists but needs to be populated with actual benchmarks.

**Tasks:**
- [ ] Create benchmark comparing QuickJS vs MicroQuickJS performance
- [ ] Benchmark memory usage for various workloads
- [ ] Benchmark execution speed for common operations
- [ ] Document performance characteristics in README

---

### 3. Gemspec Configuration
**Priority: High**
**Status: Not Started**

The `quickjs.gemspec` file needs to be created/updated.

**Tasks:**
- [ ] Set correct gem name: `quickjs` (not `mquickjs`)
- [ ] Update description to mention full QuickJS
- [ ] Add dependencies (if any)
- [ ] Configure native extension compilation
- [ ] Add post-install message about downloading QuickJS source
- [ ] Set version number (suggest 0.1.0 for initial release)
- [ ] Add authors and license information
- [ ] Configure files to include/exclude

---

### 4. Automated QuickJS Download
**Priority: Medium**
**Status: Not Started**

- Include QuickJS source directly in the gem
- Increases gem size significantly
- No download required

---

### 5. CI/CD Setup
**Priority: Medium**
**Status: Not Started**

Add GitHub Actions for automated testing and building.

**Tasks:**
- [ ] Create `.github/workflows/test.yml`
- [ ] Test on multiple Ruby versions (2.7, 3.0, 3.1, 3.2, 3.3)
- [ ] Test on multiple platforms (Linux, macOS, Windows if possible)
- [ ] Run test suite automatically on PRs
- [ ] Build gem and verify it installs correctly
- [ ] Add coverage reporting

---

### 6. Documentation Improvements
**Priority: Low**
**Status: Not Started**

**Tasks:**
- [ ] Add YARD documentation for all public methods
- [ ] Generate API documentation
- [ ] Add more code examples
- [ ] Create migration guide from mquickjs-ruby
- [ ] Document ES6+ features and examples
- [ ] Add security best practices guide

---

### 7. Additional Tests
**Priority: Medium**
**Status: Partially Complete**

**Missing Test Coverage:**
- [ ] BigInt/BigFloat operations (QuickJS-specific)
- [ ] ES6+ features (more comprehensive tests)
- [ ] Memory limit edge cases
- [ ] Timeout behavior under load
- [ ] Unicode/international character handling
- [ ] Large object/array handling
- [ ] Nested function call limits
- [ ] Error message consistency across QuickJS versions

---

### 8. Document Rake Usage in CLAUDE.md
**Priority: Medium**
**Status: Not Started**

Add section to CLAUDE.md explaining how to run rake tasks properly:

**Tasks:**
- [ ] Document that bundler may fail when running as root
- [ ] Explain gems are already installed globally in the system
- [ ] Document workaround: direct compilation with `ruby extconf.rb && make`
- [ ] Note that rake-compiler may need to be installed for rake tasks to work

---

### 9. Release Preparation
**Priority: High**
**Status: Not Started**

Before releasing to RubyGems:

**Tasks:**
- [ ] Complete gemspec configuration (#3)
- [ ] Add CHANGELOG.md with version history
- [ ] Tag initial release (v0.1.0 or v1.0.0)
- [ ] Test gem installation from source
- [ ] Test gem installation from RubyGems (after publish)
- [ ] Create release announcement

---

## Optional Enhancements

### 10. Additional Features
**Priority: Low**

These features could differentiate quickjs-ruby from alternatives:

- [ ] **Streaming API**: Support for processing large JSON/data streams
- [ ] **Worker Pools**: Multiple sandbox instances for concurrent execution
- [ ] **Persistent Contexts**: Reusable sandboxes with state preservation
- [ ] **Custom Native Functions**: Allow users to register Ruby functions callable from JS
- [ ] **Module System**: Support for ES6 imports/exports
- [ ] **Source Maps**: Better error reporting with source maps
- [ ] **Profiling**: Built-in performance profiling tools

---

## Known Limitations

Document these in README:

1. **Platform Support**:
   - macOS (tested, working)
   - Linux (should work, needs testing)
   - Windows (may need adjustments)

2. **Ruby Version Support**:
   - Minimum: Ruby 2.7 (uses TypedData API)
   - Tested: Ruby 3.3
   - Need to test: 2.7, 3.0, 3.1, 3.2

3. **Memory Overhead**:
   - QuickJS needs ~100KB minimum just to initialize
   - Each sandbox adds overhead
   - Multiple sandboxes can consume significant memory

4. **QuickJS Version**:
   - Currently locked to 2024-01-13
   - Should support upgrading to newer QuickJS versions
   - Need strategy for version updates

---

## Questions to Resolve

1. **Gem Naming**: Should it be `quickjs` or `quickjs-ruby`?
   - `quickjs` - Shorter, cleaner
   - `quickjs-ruby` - More explicit, matches repo name

2. **Version Strategy**: Start at 0.1.0 or 1.0.0?
   - 0.1.0 - Indicates beta/early stage
   - 1.0.0 - Indicates production-ready

3. **MicroQuickJS Compatibility**: Should we maintain backward compatibility?
   - Currently 100% compatible API
   - Could add QuickJS-specific features in future

4. **Source Distribution**: Vendor QuickJS or download on install?
   - Vendor: Larger gem, no internet needed
   - Download: Smaller gem, requires internet during install

---

## Technical Notes

### Ruby Exception Handling in C Callbacks

When implementing C functions that are called from JavaScript (like `fetch()`), **never use `rb_exc_raise()` directly**. Ruby's exception mechanism uses `longjmp` which bypasses QuickJS's call stack cleanup, leaving JavaScript objects in an inconsistent state.

**Correct pattern:**
1. Store the Ruby exception in a wrapper struct field
2. Return `JS_ThrowInternalError()` to QuickJS so it can clean up properly
3. After `JS_Eval()` returns, check for the pending exception and re-raise it

This ensures QuickJS properly frees all JavaScript objects before Ruby takes over exception handling.
