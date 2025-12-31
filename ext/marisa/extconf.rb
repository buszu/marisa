require "mkmf"
require "fileutils"

root   = File.expand_path(__dir__)
vendor = File.join(root, "vendor", "marisa-trie")
build  = File.join(root, "build")

cmakelists = File.join(vendor, "CMakeLists.txt")
abort "CMakeLists.txt not found at #{cmakelists}" unless File.exist?(cmakelists)

FileUtils.mkdir_p(build)

Dir.chdir(build) do
  system(
    "cmake",
    vendor,
    "-DCMAKE_BUILD_TYPE=Release",
    "-DBUILD_SHARED_LIBS=OFF"
  ) or abort "cmake configure failed"

  system("cmake", "--build", ".") or abort "cmake build failed"
end

$CXXFLAGS << " -std=c++17"
$LDFLAGS  << " #{File.join(build, "libmarisa.a")}"

create_makefile("marisa/marisa")
