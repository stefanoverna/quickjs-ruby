# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"
require "rubocop/rake_task"

# Build the native extension
Rake::ExtensionTask.new("quickjs_native") do |ext|
  ext.lib_dir = "lib/quickjs"
  ext.ext_dir = "ext/quickjs"
end

# Test task
Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
  # Disable automatic plugin loading to avoid conflicts with globally installed gems
  t.options = "--no-plugins"
end

# RuboCop task
RuboCop::RakeTask.new

# Clean task
desc "Clean build artifacts"
task :clean do
  sh "cd ext/quickjs && make clean" if File.exist?("ext/quickjs/Makefile")
  rm_f "lib/quickjs/quickjs_native.so"
  rm_f Dir.glob("ext/quickjs/*.o")
  rm_f "ext/quickjs/Makefile"
end

# Benchmark task
desc "Run benchmarks"
task benchmark: :compile do
  ruby "benchmark/runner.rb"
end

# Individual benchmark tasks
namespace :benchmark do
  desc "Run simple operations benchmark"
  task simple: :compile do
    ruby "benchmark/simple_operations.rb"
  end

  desc "Run computation benchmark"
  task computation: :compile do
    ruby "benchmark/computation.rb"
  end

  desc "Run JSON operations benchmark"
  task json: :compile do
    ruby "benchmark/json_operations.rb"
  end

  desc "Run array operations benchmark"
  task array: :compile do
    ruby "benchmark/array_operations.rb"
  end

  desc "Run sandbox overhead benchmark"
  task overhead: :compile do
    ruby "benchmark/sandbox_overhead.rb"
  end

  desc "Run memory limits benchmark"
  task memory: :compile do
    ruby "benchmark/memory_limits.rb"
  end

  desc "Run console output benchmark"
  task console: :compile do
    ruby "benchmark/console_output.rb"
  end
end

# Update quickjs from upstream
# Configuration constants
QUICKJS_URL = "https://bellard.org/quickjs/quickjs-2024-01-13.tar.xz"
QUICKJS_EXT_DIR = "ext/quickjs"

# Files to EXCLUDE from the upstream copy (Ruby-specific or not needed)
QUICKJS_EXCLUDE_FILES = %w[
  quickjs_ext.c
  quickjs_wrapper.h
  extconf.rb
  qjs.c
  qjsc.c
  run-test262.c
  repl.c
  repl.js
  unicode_gen.c
  libunicode-table.h
].freeze

desc "Update QuickJS to the latest version from bellard.org"
task :update_quickjs do
  require "fileutils"
  require "tmpdir"
  require "open-uri"

  puts "Updating QuickJS from upstream..."
  puts "Source: #{QUICKJS_URL}"
  puts ""

  # Create backup directory
  timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
  backup_dir = "#{QUICKJS_EXT_DIR}/backup_#{timestamp}"
  FileUtils.mkdir_p(backup_dir)
  puts "Creating backup in #{backup_dir}..."

  # Backup all existing C/H files
  Dir.glob("#{QUICKJS_EXT_DIR}/*.{c,h}").each do |file|
    FileUtils.cp(file, backup_dir)
  end

  puts ""
  puts "Downloading QuickJS tarball..."

  # Download and extract to a temp directory
  Dir.mktmpdir do |tmp_dir|
    tarball_path = File.join(tmp_dir, "quickjs.tar.xz")
    extract_dir = File.join(tmp_dir, "quickjs")

    # Download the tarball
    begin
      URI.open(QUICKJS_URL) do |remote|
        File.open(tarball_path, "wb") do |local|
          local.write(remote.read)
        end
      end
    rescue StandardError => e
      puts "Failed to download tarball: #{e.message}"
      puts "Restoring from backup..."
      FileUtils.cp(Dir.glob("#{backup_dir}/*"), QUICKJS_EXT_DIR)
      abort "Update failed: Could not download QuickJS"
    end

    puts "Extracting tarball..."

    # Extract the tarball
    FileUtils.mkdir_p(extract_dir)
    unless system("tar -xf #{tarball_path} -C #{extract_dir} --strip-components=1")
      puts "Failed to extract tarball. Restoring from backup..."
      FileUtils.cp(Dir.glob("#{backup_dir}/*"), QUICKJS_EXT_DIR)
      abort "Update failed: Could not extract tarball"
    end

    puts "Copying updated files..."
    puts ""

    # Get all C and H files from the extracted directory
    upstream_files = Dir.glob("#{extract_dir}/*.{c,h}").map { |f| File.basename(f) }

    # Filter out excluded files
    files_to_copy = upstream_files - QUICKJS_EXCLUDE_FILES

    if files_to_copy.empty?
      puts "No files to copy!"
      abort "Update failed: No upstream files found"
    end

    # Copy files
    copied = []
    files_to_copy.each do |file|
      src = File.join(extract_dir, file)
      dst = File.join(QUICKJS_EXT_DIR, file)

      next unless File.exist?(src)

      FileUtils.cp(src, dst)
      # Check if this is a new file or an update
      if File.exist?(File.join(backup_dir, file))
        puts "  Updated: #{file}"
      else
        puts "  Added (new): #{file}"
      end
      copied << file
    end

    puts ""
    puts "Summary:"
    puts "  Total files copied: #{copied.size}"
    puts ""

    # Show which files were excluded
    puts "Excluded files (Ruby-specific or not needed):"
    QUICKJS_EXCLUDE_FILES.each { |f| puts "  - #{f}" }
    puts ""

    # Check for files that were in backup but not copied (potentially removed upstream)
    removed_files = Dir.glob("#{backup_dir}/*.{c,h}").map { |f| File.basename(f) } -
                    copied - QUICKJS_EXCLUDE_FILES

    if removed_files.any?
      puts "WARNING: These files exist locally but not in upstream:"
      removed_files.each { |f| puts "  - #{f}" }
      puts "They have been preserved. Review manually."
      puts ""
    end
  end

  # Apply custom patches
  patches_dir = File.join(QUICKJS_EXT_DIR, "patches")
  if Dir.exist?(patches_dir)
    patch_files = Dir.glob(File.join(patches_dir, "*.patch")).sort

    if patch_files.any?
      puts "Applying custom patches..."
      patch_files.each do |patch_file|
        patch_name = File.basename(patch_file)
        puts "  Applying: #{patch_name}"

        # Apply patch from the repository root
        unless system("patch -p1 < #{patch_file}")
          puts "WARNING: Failed to apply patch: #{patch_name}"
          puts "You may need to apply this patch manually."
        end
      end
      puts ""
    end
  end

  puts "Update successful!"
  puts "Backup preserved at: #{backup_dir}"
  puts ""
  puts "Next steps:"
  puts "  1. Review changes: git diff ext/quickjs/"
  puts "  2. Clean and rebuild: rake clean compile"
  puts "  3. Run tests: rake test"
  puts "  4. Run benchmarks: rake benchmark"
  puts "  5. If everything works, commit and remove backup: rm -rf #{backup_dir}"
  puts ""
  puts "NOTE: To update to a different version, edit QUICKJS_URL in Rakefile"
  puts "See available versions at: https://bellard.org/quickjs/"
end

# Default: clean, compile, test
task default: %i[clean compile test]
