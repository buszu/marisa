# ext/marisa/extconf.rb
require "fileutils"
require "rbconfig"

ROOT   = File.expand_path(__dir__)
VENDOR = File.join(ROOT, "vendor", "marisa-trie")
RUBY_BINDINGS = File.join(VENDOR, "bindings", "ruby")

abort "marisa-trie not vendored" unless File.exist?(RUBY_BINDINGS)

# --------------------------------------------------
# 1. build marisa-trie (C++)
# --------------------------------------------------

build_dir = File.join(ROOT, "build")
FileUtils.mkdir_p(build_dir)

Dir.chdir(build_dir) do
  system("cmake", VENDOR, "-DCMAKE_BUILD_TYPE=Release") or abort "cmake failed"
  system("cmake", "--build", ".") or abort "cmake build failed"
end

# --------------------------------------------------
# 2. build ruby bindings (upstream)
# --------------------------------------------------

Dir.chdir(RUBY_BINDINGS) do
  system(RbConfig.ruby, "extconf.rb") or abort "vendor extconf failed"
  system("make") or abort "vendor make failed"
end

# --------------------------------------------------
# 3. copy compiled extension
# --------------------------------------------------

dlext = RbConfig::CONFIG["DLEXT"]
bundle = Dir[File.join(RUBY_BINDINGS, "*.#{dlext}")].first or
  abort "compiled extension not found"

FileUtils.cp(bundle, ROOT)

puts "✓ marisa extension built"

# --------------------------------------------------
# 4. SATISFY RUBYGEMS (dummy Makefile)
# --------------------------------------------------

File.write("Makefile", <<~MAKEFILE)
all:
\t@echo "marisa already built"

install:
\t@echo "marisa already installed"
MAKEFILE
