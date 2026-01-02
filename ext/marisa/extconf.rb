# frozen_string_literal: true

require "mkmf"
require "fileutils"

# --------------------------------------------------
# helpers
# --------------------------------------------------

def abort_with(msg)
  abort "\n*** marisa extconf error ***\n#{msg}\n"
end

def run!(*cmd)
  puts "→ #{cmd.join(' ')}"
  system(*cmd) || abort_with("command failed: #{cmd.join(' ')}")
end

# --------------------------------------------------
# toolchain checks
# --------------------------------------------------

%w[cmake make swig].each do |tool|
  find_executable(tool) or abort_with("#{tool} not found in PATH")
end

# --------------------------------------------------
# paths
# --------------------------------------------------

ROOT   = File.expand_path(__dir__)
VENDOR = File.join(ROOT, "vendor", "marisa-trie")
BUILD  = File.join(ROOT, "build")

abort_with "marisa-trie not vendored" unless
  File.exist?(File.join(VENDOR, "CMakeLists.txt"))

# --------------------------------------------------
# SWIG (generate wrapper if missing)
# --------------------------------------------------

wrap = File.join(ROOT, "marisa-swig_wrap.cxx")
unless File.exist?(wrap)
  Dir.chdir(ROOT) do
    run!(
      "swig",
      "-Wall",
      "-c++",
      "-ruby",
      "-outdir ruby",
      "marisa-swig.i"
    )
  end
end

# --------------------------------------------------
# build marisa-trie (C++)
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

# --------------------------------------------------
# mkmf config (Ruby extension)
# --------------------------------------------------

# headers
$INCFLAGS << " -I#{VENDOR}/include"
$INCFLAGS << " -I#{VENDOR}/bindings/ruby"

# static library
libmarisa = File.join(BUILD, "libmarisa.a")
abort_with "libmarisa.a not found" unless File.exist?(libmarisa)

$LDFLAGS << " #{libmarisa}"

# C++
CONFIG["CXX"] ||= "c++"
$CXXFLAGS << " -std=c++17"

# --------------------------------------------------
# generate Ruby Makefile
# --------------------------------------------------

create_makefile("marisa/marisa")
