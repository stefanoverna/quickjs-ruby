# Differences Between quickjs-ruby and mquickjs-ruby

This document lists all differences between this repository (quickjs-ruby) and [mquickjs-ruby](https://github.com/stefanoverna/mquickjs-ruby). The goal is to keep the two repositories as similar as possible.

## Summary

| Category | Status |
|----------|--------|
| Ruby API files | Module names differ (expected) |
| README | quickjs-ruby is missing significant content |
| test/README.md | Missing in quickjs-ruby |
| LICENSE | Different format/credits |
| CI/GitHub workflows | Identical |
| .rubocop.yml | Minor differences (path names) |
| Gemfile | Identical structure |
| Rakefile | Identical structure (different paths) |

---

## Differences That Should Be Removed

### 1. README.md - Missing Content (HIGH PRIORITY)

The mquickjs-ruby README (1518 lines) has significantly more content than quickjs-ruby (572 lines).

#### Missing Sections in quickjs-ruby:

| Section | Lines in mquickjs | Description | Priority |
|---------|-------------------|-------------|----------|
| **JavaScript Limitations** | ~150 | ES5 limitations + workarounds | High (adapt for ES2020+) |
| **Performance** | ~130 | Benchmarks, optimization tips | High |
| **Security Recommendations** | ~60 | Threat model, isolation options | High |
| **Detailed Error Handling** | ~200 | Examples for each error class | Medium |
| **Contributing** | ~30 | Development setup instructions | Medium |
| **Credits** | ~5 | Attribution to QuickJS/Bellard | Medium |
| **HTTP Response Properties** | ~20 | Response object documentation | Low |
| **How the Build Works** | ~15 | Build process explanation | Low |

**Action Required:** Update `README.md` to include equivalent sections adapted for QuickJS features.

### 2. test/README.md - Missing File (MEDIUM PRIORITY)

mquickjs-ruby has `test/README.md` (86 lines) explaining:
- Test file structure and purpose
- Test coverage goals
- Running instructions
- Prerequisites
- Known issues

**Action Required:** Add `test/README.md` with equivalent content.

### 3. LICENSE - Different Format (LOW PRIORITY)

| Aspect | quickjs-ruby | mquickjs-ruby |
|--------|-------------|---------------|
| Copyright holder | "Stefano Verna" | "MQuickJS Ruby Contributors" |
| Additional credits | None | Includes MicroQuickJS/Bellard attribution |
| Year | 2024 | 2025 |
| Format | Simple MIT | MIT + upstream credits |

**Action Required:** Consider adding QuickJS attribution to LICENSE.

### 4. .rubocop.yml - Minor Differences (LOW PRIORITY)

| Difference | quickjs-ruby | mquickjs-ruby |
|------------|-------------|---------------|
| Extra exclusion | `explorer.rb` | Not present |
| Gemspec exclusion | `quickjs.gemspec` | `mquickjs.gemspec` |
| Error file exclusion | `lib/quickjs/errors.rb` | `lib/mquickjs/errors.rb` |

**Action Required:** Sync `explorer.rb` exclusion if needed.

---

## Files That Are Identical (Except Module/Path Names)

### GitHub Workflows

| File | Status |
|------|--------|
| `.github/workflows/ci.yml` | **Identical** - same Ruby versions, same steps |

### Configuration Files

| File | quickjs-ruby | mquickjs-ruby | Differences |
|------|-------------|---------------|-------------|
| `Gemfile` | Present | Present | Only gemspec comment differs |
| `Rakefile` | Present | Present | Paths/names differ, structure identical |
| `.gemspec` | `quickjs.gemspec` | `mquickjs.gemspec` | Name, URL, description |
| `.rubocop.yml` | Present | Present | Path exclusions only |

### Ruby Files (lib/)

All these files differ only in:
- Module name: `QuickJS` vs `MQuickJS`
- Path references: `quickjs` vs `mquickjs`

| quickjs-ruby | mquickjs-ruby |
|--------------|---------------|
| `lib/quickjs.rb` | `lib/mquickjs.rb` |
| `lib/quickjs/version.rb` | `lib/mquickjs/version.rb` |
| `lib/quickjs/errors.rb` | `lib/mquickjs/errors.rb` |
| `lib/quickjs/result.rb` | `lib/mquickjs/result.rb` |
| `lib/quickjs/sandbox.rb` | `lib/mquickjs/sandbox.rb` |
| `lib/quickjs/http_config.rb` | `lib/mquickjs/http_config.rb` |
| `lib/quickjs/http_executor.rb` | `lib/mquickjs/http_executor.rb` |

### Test Files (test/)

| quickjs-ruby | mquickjs-ruby |
|--------------|---------------|
| `test/mquickjs_test.rb` | `test/mquickjs_test.rb` |
| `test/set_variable_test.rb` | `test/set_variable_test.rb` |
| `test/fetch_test.rb` | `test/fetch_test.rb` |
| `test/http_config_test.rb` | `test/http_config_test.rb` |
| `test/http_executor_test.rb` | `test/http_executor_test.rb` |
| `test/error_documentation_test.rb` | `test/error_documentation_test.rb` |
| `test/run_all_tests.rb` | `test/run_all_tests.rb` |
| N/A | `test/README.md` (**Missing**) |

### Benchmark Files (benchmark/)

All benchmark files are structurally identical, differing only in module name:
- `benchmark/runner.rb`
- `benchmark/simple_operations.rb`
- `benchmark/computation.rb`
- `benchmark/json_operations.rb`
- `benchmark/array_operations.rb`
- `benchmark/sandbox_overhead.rb`
- `benchmark/memory_limits.rb`
- `benchmark/console_output.rb`

---

## Extra Files in quickjs-ruby

| File | Description | Add to mquickjs-ruby? |
|------|-------------|----------------------|
| `CHANGELOG.md` | Version history | Consider adding |
| `TODO.md` | Development tasks | No (dev artifact) |
| `UPDATING_QUICKJS.md` | Update guide | Has `UPDATING_MQUICKJS.md` |
| `explorer.rb` | Development utility | No (dev artifact) |
| `CLAUDE.md` | Build instructions | Consider adding |
| `DIFF.md` (this file) | Comparison document | No (quickjs-only) |

---

## Recommended Actions

### Priority 1 (High): Update README.md

Add the following sections to quickjs-ruby's README.md:

1. **Performance** section with benchmark results and optimization tips
2. **Security Recommendations** section with threat model and isolation options
3. **Contributing** section with development setup instructions
4. **Credits** section for QuickJS/Fabrice Bellard attribution
5. **Detailed Error Handling** with examples for each error type

Note: The "JavaScript Limitations" section from mquickjs should be adapted to highlight ES2020+ **features** (not limitations) in quickjs-ruby.

### Priority 2 (Medium): Add Missing Files

1. Create `test/README.md` with test suite documentation

### Priority 3 (Low): Minor Synchronization

1. Consider updating LICENSE format to include QuickJS credits
2. Consider adding `CHANGELOG.md` to mquickjs-ruby

---

## Verification Checklist

When making changes, verify:

- [ ] Both repos compile without errors
- [ ] Both repos pass all tests (`rake test`)
- [ ] Both repos pass lint (`rake rubocop`)
- [ ] README reflects the correct engine (QuickJS vs MicroQuickJS)
- [ ] API documentation matches implementation
- [ ] All structural changes are mirrored in both repos
