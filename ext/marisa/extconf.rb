# frozen_string_literal: true

require "mkmf"
require "fileutils"

def abort_with(msg)
  abort "\n*** marisa extconf error ***\n#{msg}\n"
end

def run!(*cmd)
  puts "→ #{cmd.join(' ')}"
  system(*cmd) || abort_with("command failed: #{cmd.join(' ')}")
end

# --------------------------------------------------
# tools
# --------------------------------------------------

%w[cmake make].each do |tool|
  find_executable(tool) or abort_with("#{tool} not found in PATH")
end

# --------------------------------------------------
# paths
# --------------------------------------------------

ROOT   = File.expand_path(__dir__)
VENDOR = File.join(ROOT, "vendor", "marisa-trie")
BUILD  = File.join(ROOT, "build")

abort_with "marisa-trie not found" unless
  File.exist?(File.join(VENDOR, "CMakeLists.txt"))

# --------------------------------------------------
# build libmarisa (static)
# --------------------------------------------------

FileUtils.mkdir_p(BUILD)

Dir.chdir(BUILD) do
  run!(
    "cmake",
    VENDOR,
    "-DCMAKE_BUILD_TYPE=Release",
    "-DBUILD_SHARED_LIBS=OFF",
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
    "-DCMAKE_CXX_STANDARD=17",
    "-DCMAKE_CXX_STANDARD_REQUIRED=ON"
  )

  run!(
    "cmake",
    "--build", ".",
    "--", "-j#{ENV.fetch("MAKE_JOBS", 2)}"
  )
end

libmarisa = File.join(BUILD, "libmarisa.a")
abort_with "libmarisa.a not built" unless File.exist?(libmarisa)

# --------------------------------------------------
# export flags for Ruby extension
# --------------------------------------------------

$INCFLAGS << " -I#{VENDOR}/include"
$LDFLAGS  << " #{libmarisa}"
$CXXFLAGS << " -std=c++17"

# --------------------------------------------------
# delegate to original Ruby bindings
# --------------------------------------------------

Dir.chdir(File.join(VENDOR, "bindings", "ruby")) do
  puts "\n\n\nELO\n\n\n"
  puts Dir.pwd
  load "extconf.rb"
end
