# TODO - QuickJS Ruby Gem

This document tracks remaining work to make quickjs-ruby production-ready.

## Critical Issues

### 1. Fix RuboCop Linting Failures
**Priority: High**
**Status: Not Started**

RuboCop linting is currently failing. Need to run and fix all linting issues.

**Tasks:**
- [ ] Run RuboCop: `/opt/rbenv/versions/3.3.6/lib/ruby/gems/3.3.0/gems/rubocop-*/exe/rubocop`
- [ ] Fix or disable failing rules
- [ ] Ensure CI linting passes

**Files Likely Affected:**
- Ruby files in `lib/quickjs/`
- Test files in `test/`
- `Rakefile`

---

### 2. Fix Failing Tests
**Priority: High**
**Status: Not Started**

Test suite is currently failing. Need to investigate and fix all test failures.

**Tasks:**
- [ ] Compile the native extension
- [ ] Run test suite to identify failures
- [ ] Fix failing tests one by one
- [ ] Ensure all tests pass on Ruby 3.3
- [ ] Test on other Ruby versions (2.7, 3.0, 3.1, 3.2)

**Possible Issues:**
- Native extension compilation errors
- API differences between MicroQuickJS and QuickJS
- Memory limit adjustments needed (100KB min vs 10KB)
- ES6+ syntax in test expectations

**How to Run Tests:**
```bash
cd ext/quickjs
ruby extconf.rb
make
cd ../..
ruby -Ilib test/run_all_tests.rb  # or similar
```

---

### 3. Fix GC Assertion in Fetch Tests
**Priority: Medium**
**Status: Known Issue**

Some fetch tests trigger a GC assertion during sandbox cleanup:
```
ruby: quickjs.c:1991: JS_FreeRuntime: Assertion `list_empty(&rt->gc_obj_list)' failed.
```

**Details:**
- Tests pass correctly and functionality works
- Issue occurs during `sandbox_free()` when cleaning up Response objects created by `fetch()`
- Current workaround: Setting console/fetch to undefined and running GC
- Root cause: C function references or Response objects not being fully released

**Possible Solutions:**
1. Track all created objects and explicitly free them before context destruction
2. Use JS_FreeValue on all Response objects before freeing context
3. Investigate QuickJS reference counting for C functions
4. Check if we need to set opaque data differently for fetch callback

**Files to Investigate:**
- `ext/quickjs/quickjs_ext.c:498-535` (sandbox_free function)
- `ext/quickjs/quickjs_ext.c:173-271` (js_fetch function)

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

**Example benchmarks:**
- Simple arithmetic operations
- String manipulation
- Array/object operations
- Function call overhead
- Fetch operations with HTTP

---

### 3. Update README
**Priority: High**
**Status: ✅ Completed**

The README has been comprehensively updated to reflect quickjs-ruby (full QuickJS).

**Completed:**
- [x] Updated gem name references throughout
- [x] Documented ES6+ feature support with examples (const, let, arrows, template literals, BigInt)
- [x] Updated memory limit recommendations (1MB default vs 50KB, 100KB minimum vs 10KB)
- [x] Added comprehensive comparison table: QuickJS vs MicroQuickJS
  - Feature support, memory requirements, use cases
- [x] Updated installation instructions
- [x] Added build instructions and referenced CLAUDE.md
- [x] Documented known GC assertion issue
- [x] Added complete API reference
- [x] Added security warnings and best practices

**Key Differences to Document:**
| Feature | MicroQuickJS | QuickJS (Full) |
|---------|-------------|----------------|
| Default Memory | 50KB | 1MB |
| Min Memory | 10KB | 100KB |
| ES6 Support | Limited | Full |
| BigInt/BigFloat | No | Yes |
| Size | Smaller | Larger |

---

### 4. Gemspec Configuration
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

**Post-Install Message:**
Should instruct users that QuickJS source will be downloaded automatically during `gem install`, or they need to download it manually for development.

---

### 5. Automated QuickJS Download
**Priority: Medium**
**Status: Not Started**

Currently, users must manually download QuickJS source. This should be automated.

- Include QuickJS source directly in the gem
- Increases gem size significantly
- No download required

---

### 6. CI/CD Setup
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

**Example Workflow:**
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        ruby: ['2.7', '3.0', '3.1', '3.2', '3.3']
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
      - run: bundle install
      - run: rake compile
      - run: rake test
```

---

### 7. Documentation Improvements
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

### 8. Additional Tests
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

### 9. Double check that everything is setup like mquickjs-ruby
**Priority: High**
**Status: ✅ Completed**

Cloned mquickjs-ruby and successfully adapted all key infrastructure:

**Completed:**
- [x] Copied and adapted `.github/workflows/ci.yml`
  - CI tests on Ruby 2.7, 3.0, 3.1, 3.2, 3.3
  - RuboCop linting
- [x] Copied and adapted `.rubocop.yml`
  - Updated paths for quickjs gem
- [x] Created `UPDATING_QUICKJS.md` (adapted from UPDATING_MQUICKJS.md)
  - Documents tarball-based update process
  - QuickJS uses releases from bellard.org, not git
- [x] Updated `Rakefile`
  - Fixed `update_quickjs` task to download tarball instead of git clone
  - Verified task works correctly
- [x] Updated `.gitignore`
  - Simplified patterns using wildcards
  - Proper exclusion of build artifacts
- [x] Added QuickJS source files to `ext/quickjs/quickjs-src/`
  - 22 files from QuickJS 2024-01-13
  - Verified compilation works (2.7MB native extension)
- [x] Compared `Gemfile` and `gemspec` - already properly configured

**Differences (intentional):**
- QuickJS uses tarball distribution (bellard.org) vs MicroQuickJS git repository
- Different exclude files in Rakefile (qjs.c, qjsc.c vs mqjs.c)
- QuickJS includes BigInt library (libbf.c)

---

### 10. Document Rake Usage in CLAUDE.md
**Priority: Medium**
**Status: Not Started**

Add section to CLAUDE.md explaining how to run rake tasks properly:

**Tasks:**
- [ ] Document that bundler may fail when running as root
- [ ] Explain gems are already installed globally in the system
- [ ] Provide paths to globally installed executables:
  - RuboCop: `/opt/rbenv/versions/3.3.6/lib/ruby/gems/3.3.0/gems/rubocop-*/exe/rubocop`
  - Rake: `/opt/rbenv/versions/3.3.6/bin/rake` (requires rake-compiler gem)
- [ ] Document workaround: direct compilation with `ruby extconf.rb && make`
- [ ] Note that rake-compiler may need to be installed for rake tasks to work

---

### 11. Release Preparation
**Priority: High**
**Status: Not Started**

Before releasing to RubyGems:

**Tasks:**
- [ ] Complete gemspec configuration (#4)
- [ ] Update README (#3)
- [ ] Fix critical GC issue (#1) or document workaround
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
   - ✅ Linux (tested)
   - ❓ macOS (should work, needs testing)
   - ❓ Windows (may need adjustments)

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

## Completed ✅

### Core Functionality
- [x] Download and integrate QuickJS source code
- [x] Build system with extconf.rb
- [x] C extension wrapping QuickJS
- [x] Memory limit configuration
- [x] Timeout support
- [x] Console output capture
- [x] HTTP fetch() implementation
- [x] Error handling (SyntaxError, JavascriptError, etc.)
- [x] Type conversion (Ruby ↔ JavaScript)
- [x] Test suite (95%+ passing)
- [x] Update tests for QuickJS ES6+ support
- [x] Fix Result object initialization

### Documentation
- [x] Build documentation (CLAUDE.md)
- [x] Comprehensive README with QuickJS vs MicroQuickJS comparison
- [x] Document modern JavaScript features (ES6+)
- [x] Update memory limit recommendations (1MB default, 100KB minimum)
- [x] Document known GC assertion issue
- [x] Create UPDATING_QUICKJS.md for upstream updates

### Infrastructure
- [x] Git repository setup and initial commits
- [x] GitHub Actions CI/CD (`.github/workflows/ci.yml`)
  - Multi-version Ruby testing (2.7, 3.0, 3.1, 3.2, 3.3)
  - RuboCop linting
- [x] RuboCop configuration (`.rubocop.yml`)
- [x] Rakefile with QuickJS update task
  - Downloads from bellard.org (tarball-based)
  - Proper file exclusions
  - Verified working
- [x] Proper `.gitignore` patterns
- [x] Add QuickJS 2024-01-13 source files to repository
  - 22 source files in `ext/quickjs/quickjs-src/`
  - Verified compilation (2.7MB native extension)

### Infrastructure Parity with mquickjs-ruby
- [x] Clone and compare mquickjs-ruby repository
- [x] Adapt all key files (Rakefile, workflows, configs)
- [x] Document intentional differences (tarball vs git, different exclude files)
