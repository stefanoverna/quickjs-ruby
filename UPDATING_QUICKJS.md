# Updating QuickJS to the Latest Version

This document explains how to update the QuickJS library to the latest upstream version.

## Quick Start

```bash
rake update_quickjs
rake clean compile test
```

## File Architecture

Everything lives in `ext/quickjs/`. There are two types of files:

### Your Files (Protected)

These are **never overwritten** by `rake update_quickjs`:

| File | Purpose |
|------|---------|
| `quickjs_ext.c` | Ruby extension wrapper (C bindings) |
| `extconf.rb` | Build configuration |

### Upstream Files (Managed)

These come from [QuickJS on GitHub](https://github.com/bellard/quickjs) and are updated by `rake update_quickjs`:

| File | Purpose |
|------|---------|
| `quickjs.c`, `quickjs.h` | Main QuickJS engine |
| `quickjs-libc.c`, `quickjs-libc.h` | C standard library bindings |
| `libbf.c`, `libbf.h` | BigFloat/BigInt library |
| `libregexp.c`, `libregexp.h` | Regular expression support |
| `libunicode.c`, `libunicode.h` | Unicode support |
| `cutils.c`, `cutils.h` | Utility functions |
| `*.h` (various) | Header files |

## What `rake update_quickjs` Does

1. Clones the latest QuickJS from GitHub
2. Copies all `.c` and `.h` files to `ext/quickjs/`
3. **Skips** your files (listed in `QUICKJS_EXCLUDE_FILES` in Rakefile)
4. Creates a timestamped backup before overwriting

## Full Update Process

```bash
# 1. Update the files
rake update_quickjs

# 2. Review the changes
git diff ext/quickjs/

# 3. Clean and rebuild
rake clean compile

# 4. Run tests
rake test

# 5. If everything works, commit
git add ext/quickjs/
git commit -m "Update QuickJS to YYYY-MM-DD"

# 6. Clean up backups
rm -rf ext/quickjs/backup_*
```

## If Something Goes Wrong

### Restore from Backup

The update task creates a timestamped backup:

```bash
# Find the backup
ls -la ext/quickjs/backup_*

# Restore
cp ext/quickjs/backup_YYYYMMDD_HHMMSS/* ext/quickjs/

# Rebuild
rake clean compile
```

### Common Issues

**Build fails after update:**
- Check if upstream added new source files (add them to `extconf.rb`)
- Check if upstream removed source files (remove them from `extconf.rb`)
- Check for API changes in `quickjs.h`

**Tests fail after update:**
- JavaScript engine behavior may have changed
- Check memory management changes
- Run individual tests to isolate the issue

## Adding/Removing Source Files

If upstream adds or removes `.c` files, update `extconf.rb`:

```ruby
$srcs = %w[
  quickjs_ext.c      # YOUR file - always keep this
  quickjs.c          # Upstream files below
  libregexp.c
  libunicode.c
  cutils.c
  libbf.c
  quickjs-libc.c
  new_file.c         # Add new upstream files here
]
```

## Protected Files List

The `QUICKJS_EXCLUDE_FILES` constant in `Rakefile` protects these files from being overwritten:

```ruby
QUICKJS_EXCLUDE_FILES = %w[
  quickjs_ext.c       # Your Ruby extension
  extconf.rb          # Your build config
  qjs.c               # QuickJS CLI (not needed)
  qjsc.c              # QuickJS compiler (not needed)
  run-test262.c       # Test runner (not needed)
  unicode_gen.c       # Generator tool (not needed)
]
```

## Manual Update (Alternative)

If you prefer manual control:

```bash
# Clone QuickJS
git clone --depth 1 https://github.com/bellard/quickjs.git /tmp/quickjs

# Copy core files (preserving your files)
cp /tmp/quickjs/*.{c,h} ext/quickjs/
git checkout ext/quickjs/quickjs_ext.c
git checkout ext/quickjs/extconf.rb

# Rebuild
rake clean compile test
```
