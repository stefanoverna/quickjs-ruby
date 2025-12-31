# Updating QuickJS to the Latest Version

This document explains how to update the QuickJS library to the latest upstream version.

## Quick Start

```bash
rake update_quickjs
```

This will automatically download and update all necessary files from the [official QuickJS releases](https://bellard.org/quickjs/).

## What Gets Updated

The rake task automatically:

1. **Downloads** the latest QuickJS release from bellard.org
2. **Extracts** the tarball
3. **Copies** all C and H files except Ruby-specific and excluded files
4. **Creates a backup** of existing files (with timestamp)
5. **Detects new files** automatically (future-proof)
6. **Warns about removed files** if any exist locally but not upstream

## Files Updated from Upstream

The task copies ALL `.c` and `.h` files from upstream, EXCEPT:

### Excluded Files (Ruby-specific)
- `quickjs_ext.c` - Ruby native extension binding
- `quickjs_wrapper.h` - Ruby-specific wrapper
- `extconf.rb` - Ruby extension build configuration

### Excluded Files (Not needed)
- `qjs.c` - REPL implementation (not needed for embedding)
- `qjsc.c` - QuickJS compiler (not needed for embedding)
- `run-test262.c` - Test runner
- `repl.c`, `repl.js` - REPL implementation
- `examples/*.c` - Example files

## Files Typically Updated

Core engine files that get updated:
- `quickjs.c`, `quickjs.h` - Main QuickJS engine
- `quickjs-libc.c`, `quickjs-libc.h` - C standard library bindings
- `quickjs-opcode.h` - VM opcodes
- `quickjs-atom.h` - Atom definitions
- `cutils.c`, `cutils.h` - Utility functions
- `libbf.c`, `libbf.h` - BigFloat/BigInt library
- `libunicode.c`, `libunicode.h` - Unicode support
- `libregexp.c`, `libregexp.h` - Regular expression support
- `list.h` - List data structure

**Plus any new files added by upstream** (automatically included!).

## Full Update Process

1. **Update the files**:
   ```bash
   rake update_quickjs
   ```

2. **Review the changes**:
   ```bash
   git diff ext/quickjs/
   ```

3. **Clean and rebuild**:
   ```bash
   rake clean
   rake compile
   ```

4. **Run tests**:
   ```bash
   rake test
   ```

5. **Run benchmarks** (optional but recommended):
   ```bash
   rake benchmark
   ```

6. **If everything works**, commit and cleanup:
   ```bash
   git add ext/quickjs/
   git commit -m "Update QuickJS to version YYYY-MM-DD"
   rm -rf ext/quickjs/backup_*
   ```

## If Something Goes Wrong

### Restore from backup

If the update breaks something, the task creates a timestamped backup directory:

```bash
# Find the backup
ls -la ext/quickjs/backup_*

# Restore all files
cp ext/quickjs/backup_YYYYMMDD_HHMMSS/* ext/quickjs/

# Rebuild
rake clean compile
```

### Check for API changes

If tests fail after updating, check for:

1. **Changed C API** - Review `quickjs.h` for API changes
2. **Changed opcodes** - Check `quickjs-opcode.h`
3. **New required files** - The task will report "Added (new)" files
4. **Removed files** - The task will warn about files that exist locally but not upstream

You may need to update `ext/quickjs/quickjs_ext.c` if the C API changed.

## Manual Update (Alternative)

If you prefer manual control:

1. Download QuickJS:
   ```bash
   cd /tmp
   curl -L https://bellard.org/quickjs/quickjs-2024-01-13.tar.xz -o quickjs.tar.xz
   tar -xf quickjs.tar.xz
   ```

2. Copy files manually:
   ```bash
   # Copy core files (adjust list as needed)
   cp /tmp/quickjs-2024-01-13/*.{c,h} ext/quickjs/

   # Don't overwrite Ruby-specific files
   git checkout ext/quickjs/quickjs_ext.c
   git checkout ext/quickjs/quickjs_wrapper.h
   git checkout ext/quickjs/extconf.rb
   ```

3. Rebuild:
   ```bash
   rake clean compile test
   ```

## Checking Upstream Version

To see what's available upstream:

```bash
# Visit the official QuickJS website
open https://bellard.org/quickjs/

# Check the CHANGELOG
curl -s https://bellard.org/quickjs/Changelog
```

## Troubleshooting

### Build fails after update

1. Check if upstream added new dependencies
2. Review the error message from the compiler
3. Check if the C API changed in `quickjs.h`
4. Restore from backup and investigate incrementally

### Tests fail after update

1. Check for JavaScript engine behavior changes
2. Review changes in `quickjs.c` related to memory management
3. Check for changes in error handling
4. Run individual tests to isolate the issue

### New compiler warnings

1. Review the warnings - they may indicate real issues
2. Check if upstream fixed any undefined behavior
3. Consider updating compiler flags in `extconf.rb` if needed

## Version Tracking

QuickJS uses date-based versioning (e.g., `2024-01-13`). The version is typically found in:
- The tarball filename
- The `Changelog` file in the distribution
- Sometimes in comments at the top of `quickjs.c`

## Future-Proofing

This rake task is designed to be **future-proof**:

- ✅ Automatically detects new upstream files
- ✅ Warns about removed files
- ✅ Preserves Ruby-specific customizations
- ✅ Creates timestamped backups
- ✅ No hardcoded file lists to maintain

If upstream adds new files, they'll be automatically included!

## Differences from MicroQuickJS

Note that this gem uses **full QuickJS**, not MicroQuickJS:

- QuickJS is distributed as tarballs from bellard.org
- MicroQuickJS is a git repository on GitHub
- QuickJS includes BigInt/BigFloat support (libbf.c)
- QuickJS has full ES2020+ support
- QuickJS requires more memory but offers more features
