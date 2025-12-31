# frozen_string_literal: true

require 'mkmf'

# Add compilation flags
$CFLAGS << ' -std=gnu99 -Wall -Wextra -Wno-unused-parameter'
$CFLAGS << ' -D_GNU_SOURCE'  # For asprintf
$CFLAGS << ' -DCONFIG_VERSION=\"2024-12-22\"'  # QuickJS version

# Source files to compile
# - quickjs_ext.c: Our Ruby extension wrapper
# - Everything else: Upstream QuickJS (managed by `rake update_quickjs`)
$srcs = %w[
  quickjs_ext.c
  quickjs.c
  libregexp.c
  libunicode.c
  cutils.c
  libbf.c
  quickjs-libc.c
]
$objs = $srcs.map { |f| f.sub(/\.c$/, '.o') }

# Create Makefile
create_makefile('quickjs/quickjs_native')
