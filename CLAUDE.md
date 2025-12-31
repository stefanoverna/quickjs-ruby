# QuickJS Ruby Gem - Build Instructions

This document describes how to build the quickjs-ruby gem from source.

## Prerequisites

- Ruby 2.7 or higher
- C compiler (gcc or clang)
- Make
- curl or wget (for downloading QuickJS source)

## Building the Native Extension

### Step 1: Download QuickJS Source Code

The gem requires the QuickJS source code to be present in `ext/quickjs/quickjs-src/`.

```bash
cd ext/quickjs/quickjs-src
curl -L https://bellard.org/quickjs/quickjs-2024-01-13.tar.xz -o quickjs.tar.xz
tar -xf quickjs.tar.xz --strip-components=1
rm quickjs.tar.xz
```

### Step 2: Build the Extension

```bash
cd ext/quickjs
ruby extconf.rb
make
```

This will:
1. Generate a Makefile based on your system configuration
2. Compile QuickJS source files (quickjs.c, libregexp.c, libunicode.c, cutils.c, libbf.c)
3. Compile the Ruby extension wrapper (quickjs_ext.c)
4. Link everything into `quickjs_native.so`

### Step 3: Copy the Extension (for Development)

For development/testing, copy the compiled extension to the lib directory:

```bash
cp quickjs_native.so ../../lib/quickjs/
```

### Step 4: Test the Installation

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

## Key Differences from MicroQuickJS

This gem wraps the **full QuickJS engine**, not MicroQuickJS. Key differences:

1. **Memory Requirements**: QuickJS requires more memory than MicroQuickJS
   - Default memory limit: 1MB (vs 50KB for MicroQuickJS)
   - Minimum recommended: 100KB (vs 10KB for MicroQuickJS)

2. **Features**: Full QuickJS includes:
   - BigInt/BigFloat support (via libbf.c)
   - Complete ES2020+ support
   - More comprehensive standard library

3. **Source Files**: Requires compiling additional files:
   - `libbf.c` - BigNum library (not needed in MicroQuickJS)

## Troubleshooting

### Symbol Errors (e.g., `undefined symbol: bf_context_init`)

This means `libbf.c` wasn't compiled. Make sure your `extconf.rb` includes it in the source list.

### Memory Errors on Simple Scripts

If simple scripts like `1 + 1` fail with errors, the memory limit is too low. QuickJS needs at least 100KB to initialize properly.

### Build Errors

1. Make sure you have a C compiler installed: `gcc --version` or `clang --version`
2. Verify Ruby development headers are installed: `ruby -rrbconfig -e "puts RbConfig::CONFIG['includedir']"`
3. Check that QuickJS source was downloaded correctly: `ls ext/quickjs/quickjs-src/quickjs.c`

## Files Overview

- `ext/quickjs/extconf.rb` - Build configuration
- `ext/quickjs/quickjs_ext.c` - C extension implementation
- `ext/quickjs/quickjs-src/` - QuickJS source code (downloaded separately)
- `lib/quickjs.rb` - Ruby interface
- `lib/quickjs/*.rb` - Ruby classes (Sandbox, Result, Errors, etc.)
