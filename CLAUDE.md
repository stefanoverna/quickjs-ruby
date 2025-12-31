# QuickJS Ruby Gem - Build Instructions

This document describes how to build the quickjs-ruby gem from source.

## Prerequisites

- Ruby 2.7 or higher
- C compiler (gcc or clang)
- Make

## Building the Native Extension

The QuickJS source files are included in the repository under `ext/quickjs/`.

### Step 1: Build the Extension

```bash
cd ext/quickjs
ruby extconf.rb
make
```

This will:
1. Generate a Makefile based on your system configuration
2. Compile QuickJS source files (quickjs.c, libregexp.c, libunicode.c, cutils.c, dtoa.c, quickjs-libc.c)
3. Compile the Ruby extension wrapper (quickjs_ext.c)
4. Link everything into `quickjs_native.so`

### Step 2: Copy the Extension (for Development)

For development/testing, copy the compiled extension to the lib directory:

```bash
cp quickjs_native.so ../../lib/quickjs/
```

### Step 3: Test the Installation

```bash
cd ../..  # Back to project root
ruby -Ilib -e "require 'quickjs'; puts QuickJS.eval('1 + 1').value"
```

You should see `2` printed.

## Alternative: Using Rake

You can also use the provided Rakefile:

```bash
bundle install
rake compile
rake test
```

## Updating QuickJS

To update QuickJS to the latest version from upstream:

```bash
rake update_quickjs
```

This will clone the latest QuickJS from GitHub and copy the needed files.

## Key Differences from MicroQuickJS

This gem wraps the **full QuickJS engine**, not MicroQuickJS. Key differences:

1. **Memory Requirements**: QuickJS requires more memory than MicroQuickJS
   - Default memory limit: 1MB (vs 50KB for MicroQuickJS)
   - Minimum recommended: 100KB (vs 10KB for MicroQuickJS)

2. **Features**: Full QuickJS includes:
   - BigInt support
   - Complete ES2020+ support
   - More comprehensive standard library

## Troubleshooting

### Memory Errors on Simple Scripts

If simple scripts like `1 + 1` fail with errors, the memory limit is too low. QuickJS needs at least 100KB to initialize properly.

### Build Errors

1. Make sure you have a C compiler installed: `gcc --version` or `clang --version`
2. Verify Ruby development headers are installed: `ruby -rrbconfig -e "puts RbConfig::CONFIG['includedir']"`
3. Check that QuickJS source is present: `ls ext/quickjs/quickjs.c`

## Files Overview

- `ext/quickjs/extconf.rb` - Build configuration
- `ext/quickjs/quickjs_ext.c` - C extension implementation
- `ext/quickjs/quickjs.c` - Main QuickJS engine source
- `ext/quickjs/*.c` - Other QuickJS source files
- `lib/quickjs.rb` - Ruby interface
- `lib/quickjs/*.rb` - Ruby classes (Sandbox, Result, Errors, etc.)
