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
MQUICKJS_GITHUB_REPO = "https://github.com/bellard/quickjs.git"
MQUICKJS_EXT_DIR = "ext/quickjs"

# Files to EXCLUDE from the upstream copy (Ruby-specific or not needed)
MQUICKJS_EXCLUDE_FILES = %w[
  quickjs_ext.c
  quickjs_wrapper.h
  extconf.rb
  mqjs.c
  readline.c
  readline.h
  readline_tty.c
  readline_tty.h
  example.c
  example_stdlib.c
].freeze

# Generated files that will be recreated during build (backup but don't copy from upstream)
MQUICKJS_GENERATED_FILES = %w[
  quickjs_atom.h
  mqjs_stdlib.h
].freeze

desc "Update quickjs to the latest version from GitHub"
task :update_quickjs do
  require "fileutils"
  require "tmpdir"

  puts "Updating quickjs from upstream repository..."
  puts "Source: #{MQUICKJS_GITHUB_REPO}"
  puts ""

  # Create backup directory
  timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
  backup_dir = "#{MQUICKJS_EXT_DIR}/backup_#{timestamp}"
  FileUtils.mkdir_p(backup_dir)
  puts "Creating backup in #{backup_dir}..."

  # Backup all existing C/H files
  Dir.glob("#{MQUICKJS_EXT_DIR}/*.{c,h}").each do |file|
    FileUtils.cp(file, backup_dir)
  end

  puts ""
  puts "Cloning quickjs repository..."

  # Clone the repository to a temp directory
  Dir.mktmpdir do |tmp_dir|
    clone_dir = File.join(tmp_dir, "quickjs")

    # Clone the repository
    unless system("git clone --depth 1 --quiet #{MQUICKJS_GITHUB_REPO} #{clone_dir}")
      puts "Failed to clone repository. Restoring from backup..."
      FileUtils.cp(Dir.glob("#{backup_dir}/*"), MQUICKJS_EXT_DIR)
      abort "Update failed: Could not clone repository"
    end

    puts "Copying updated files..."
    puts ""

    # Get all C and H files from the cloned repo
    upstream_files = Dir.glob("#{clone_dir}/*.{c,h}").map { |f| File.basename(f) }

    # Filter out excluded files
    files_to_copy = upstream_files - MQUICKJS_EXCLUDE_FILES - MQUICKJS_GENERATED_FILES

    if files_to_copy.empty?
      puts "No files to copy!"
      abort "Update failed: No upstream files found"
    end

    # Copy files
    copied = []
    files_to_copy.each do |file|
      src = File.join(clone_dir, file)
      dst = File.join(MQUICKJS_EXT_DIR, file)

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
    puts "Excluded files (Ruby-specific):"
    MQUICKJS_EXCLUDE_FILES.each { |f| puts "  - #{f}" }
    puts ""

    puts "Generated files (will be recreated during build):"
    MQUICKJS_GENERATED_FILES.each { |f| puts "  - #{f}" }
    puts ""

    # Check for files that were in backup but not copied (potentially removed upstream)
    removed_files = Dir.glob("#{backup_dir}/*.{c,h}").map { |f| File.basename(f) } -
                    copied - MQUICKJS_EXCLUDE_FILES - MQUICKJS_GENERATED_FILES

    if removed_files.any?
      puts "WARNING: These files exist locally but not in upstream:"
      removed_files.each { |f| puts "  - #{f}" }
      puts "They have been preserved. Review manually."
      puts ""
    end
  end

  # Apply custom patches
  patches_dir = File.join(MQUICKJS_EXT_DIR, "patches")
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
  puts "Note: Generated files (quickjs_atom.h, mqjs_stdlib.h) will be"
  puts "recreated automatically during the next build (step 2)."
  puts ""
  puts "Custom patches from ext/quickjs/patches/ have been applied."
end

# Default: clean, compile, test
task default: %i[clean compile test]
