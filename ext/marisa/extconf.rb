require "mkmf"
require "fileutils"

ROOT = File.expand_path(__dir__)
VENDOR = File.join(ROOT, "vendor", "marisa-trie")
BUILD  = File.join(ROOT, "build")

FileUtils.mkdir_p BUILD
Dir.chdir(BUILD) do
  system("cmake", VENDOR,
    "-DBUILD_SHARED_LIBS=OFF",
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  ) or abort "cmake failed"

  system("make") or abort "make failed"
end

$INCFLAGS << " -I#{VENDOR}/include"
$LDFLAGS  << " #{BUILD}/libmarisa.a"

create_makefile("marisa")
