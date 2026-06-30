# CMake toolchain file: ARM32 Linux, musl libc, fully STATIC
# Toolchain: musl.cc arm-linux-musleabihf (GCC 11.2.1, musl)
# Produces fully static executables with NO libc dependency — run on any ARM Linux.
#
# Usage:
#   cmake -B build-arm32-musl \
#     -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-musl-static.cmake \
#     -DCMAKE_BUILD_TYPE=Release
#   cmake --build build-arm32-musl -j

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Root of the extracted musl.cc toolchain (override with -DARM_MUSL_TOOLCHAIN_ROOT=...)
if(NOT ARM_MUSL_TOOLCHAIN_ROOT)
  set(ARM_MUSL_TOOLCHAIN_ROOT "/opt/arm-gnu/arm-linux-musleabihf-cross")
endif()

set(CROSS_PREFIX "${ARM_MUSL_TOOLCHAIN_ROOT}/bin/arm-linux-musleabihf-")

set(CMAKE_C_COMPILER   "${CROSS_PREFIX}gcc")
set(CMAKE_CXX_COMPILER "${CROSS_PREFIX}g++")
set(CMAKE_ASM_COMPILER "${CROSS_PREFIX}gcc")
set(CMAKE_AR           "${CROSS_PREFIX}ar")
set(CMAKE_RANLIB       "${CROSS_PREFIX}ranlib")
set(CMAKE_STRIP        "${CROSS_PREFIX}strip")

# ARMv7-A hard-float
set(ARM_FLAGS "-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=hard")
set(CMAKE_C_FLAGS_INIT   "${ARM_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${ARM_FLAGS}")

# Fully static link (musl makes this clean: no glibc/NSS surprises)
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static")
# Make CMake's compiler/link checks use static too, so feature detection matches
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Forward the root to CMake's try_compile sub-project (see arm glibc toolchain).
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES ARM_MUSL_TOOLCHAIN_ROOT)

set(CMAKE_FIND_ROOT_PATH "${ARM_MUSL_TOOLCHAIN_ROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
