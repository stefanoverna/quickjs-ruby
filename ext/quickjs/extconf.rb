# frozen_string_literal: true

require 'mkmf'
require 'fileutils'

# Configuration
QUICKJS_DIR = File.join(__dir__, 'quickjs-src')
EXT_DIR = __dir__

# Add QuickJS source directory to include path
$INCFLAGS << " -I#{QUICKJS_DIR}"

# Add compilation flags
$CFLAGS << ' -std=gnu99 -Wall -Wextra -Wno-unused-parameter'
$CFLAGS << ' -D_GNU_SOURCE'  # For asprintf
$CFLAGS << ' -DCONFIG_VERSION=\"2024-01-13\"'  # QuickJS version

# QuickJS source files to compile
quickjs_sources = %w[
  quickjs.c
  libregexp.c
  libunicode.c
  cutils.c
].map { |f| File.join(QUICKJS_DIR, f) }

# Add QuickJS sources to the source list
$srcs = ['quickjs_ext.c'] + quickjs_sources.map { |f| File.basename(f) }
$objs = $srcs.map { |f| f.sub(/\.c$/, '.o') }

# Copy QuickJS source files to ext directory for compilation
quickjs_sources.each do |src|
  dest = File.join(EXT_DIR, File.basename(src))
  unless File.exist?(dest)
    FileUtils.cp(src, dest)
  end
end

# Also copy header files
Dir.glob(File.join(QUICKJS_DIR, '*.h')).each do |src|
  dest = File.join(EXT_DIR, File.basename(src))
  unless File.exist?(dest)
    FileUtils.cp(src, dest)
  end
end

# Create Makefile
create_makefile('quickjs/quickjs_native')
