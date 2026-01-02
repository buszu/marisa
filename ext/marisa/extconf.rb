# ext/marisa/extconf.rb
require "mkmf"
require "fileutils"

ROOT   = File.expand_path(__dir__)
VENDOR = File.join(ROOT, "vendor", "marisa-trie")
BUILD  = File.join(ROOT, "build")

abort "marisa-trie not vendored" unless
  File.exist?(File.join(VENDOR, "CMakeLists.txt"))

# --------------------------------------------------
# 1. build marisa-trie (static lib)
# --------------------------------------------------

FileUtils.mkdir_p(BUILD)

Dir.chdir(BUILD) do
  system(
    "cmake",
    VENDOR,
    "-DCMAKE_BUILD_TYPE=Release",
    "-DBUILD_SHARED_LIBS=OFF",
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  ) or abort "cmake configure failed"

  system("cmake", "--build", ".") or abort "cmake build failed"
end

libmarisa = File.join(BUILD, "libmarisa.a")
abort "libmarisa.a not found" unless File.exist?(libmarisa)

# --------------------------------------------------
# 2. SWIG wrapper (Ruby)
# --------------------------------------------------

bindings = File.join(VENDOR, "bindings")
ruby_bindings = File.join(bindings, "ruby")

wrap = File.join(ruby_bindings, "marisa-swig_wrap.cxx")
unless File.exist?(wrap)
  Dir.chdir(bindings) do
    system(
      "swig",
      "-c++",
      "-ruby",
      "-outdir", ruby_bindings,
      "marisa-swig.i"
    ) or abort "swig failed"
  end
end

wrap_dst = File.join(ROOT, "marisa-swig_wrap.cxx")
FileUtils.cp(wrap, wrap_dst)

# --------------------------------------------------
# 3. mkmf config (THIS IS THE KEY PART)
# --------------------------------------------------

$INCFLAGS << " -I#{VENDOR}/include"
$INCFLAGS << " -I#{ruby_bindings}"

$CXXFLAGS << " -std=c++17"
$LDFLAGS  << " #{libmarisa}"

CONFIG["CXX"] ||= "c++"

# --------------------------------------------------
# 4. create Makefile (ABSOLUTELY REQUIRED)
# --------------------------------------------------

create_makefile("marisa/marisa")
