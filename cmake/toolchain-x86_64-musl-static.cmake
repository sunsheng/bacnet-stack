# CMake toolchain file: Linux x86_64, musl libc, fully STATIC
# Toolchain: musl.cc x86_64-linux-musl (GCC 11.2.1, musl)
# Produces fully static executables with NO libc dependency — run on any x86_64 Linux.
#
# Usage:
#   cmake -B build-linux-x86_64-musl \
#     -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-x86_64-musl-static.cmake \
#     -DCMAKE_BUILD_TYPE=Release
#   cmake --build build-linux-x86_64-musl -j

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Root of the extracted musl.cc toolchain (override with -DX86_64_MUSL_TOOLCHAIN_ROOT=...)
if(NOT X86_64_MUSL_TOOLCHAIN_ROOT)
  set(X86_64_MUSL_TOOLCHAIN_ROOT "/opt/arm-gnu/x86_64-linux-musl-cross")
endif()

set(CROSS_PREFIX "${X86_64_MUSL_TOOLCHAIN_ROOT}/bin/x86_64-linux-musl-")

set(CMAKE_C_COMPILER   "${CROSS_PREFIX}gcc")
set(CMAKE_CXX_COMPILER "${CROSS_PREFIX}g++")
set(CMAKE_ASM_COMPILER "${CROSS_PREFIX}gcc")
set(CMAKE_AR           "${CROSS_PREFIX}ar")
set(CMAKE_RANLIB       "${CROSS_PREFIX}ranlib")
set(CMAKE_STRIP        "${CROSS_PREFIX}strip")

# Fully static link (musl makes this clean: no glibc/NSS surprises)
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static")
# Make CMake's compiler/link checks use static too, so feature detection matches
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Forward the root to CMake's try_compile sub-project (see arm glibc toolchain).
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES X86_64_MUSL_TOOLCHAIN_ROOT)

set(CMAKE_FIND_ROOT_PATH "${X86_64_MUSL_TOOLCHAIN_ROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
