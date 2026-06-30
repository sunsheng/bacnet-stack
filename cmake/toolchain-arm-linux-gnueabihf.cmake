# CMake toolchain file: ARM32 Linux (armhf, ARMv7 hard-float)
# Toolchain: Arm GNU-A 10.2-2020.11 arm-none-linux-gnueabihf (GCC 10.2.1, glibc 2.31)
#
# Usage:
#   cmake -B build-arm32 \
#     -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-linux-gnueabihf.cmake \
#     -DCMAKE_BUILD_TYPE=Release
#   cmake --build build-arm32 -j

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Root of the extracted Arm GNU-A toolchain (override with -DARM_TOOLCHAIN_ROOT=...)
if(NOT ARM_TOOLCHAIN_ROOT)
  set(ARM_TOOLCHAIN_ROOT
      "/opt/arm-gnu/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf")
endif()

set(CROSS_PREFIX "${ARM_TOOLCHAIN_ROOT}/bin/arm-none-linux-gnueabihf-")

set(CMAKE_C_COMPILER   "${CROSS_PREFIX}gcc")
set(CMAKE_CXX_COMPILER "${CROSS_PREFIX}g++")
set(CMAKE_ASM_COMPILER "${CROSS_PREFIX}gcc")
set(CMAKE_AR           "${CROSS_PREFIX}ar")
set(CMAKE_RANLIB       "${CROSS_PREFIX}ranlib")
set(CMAKE_STRIP        "${CROSS_PREFIX}strip")

# Sysroot shipped with the toolchain (provides glibc 2.31 headers/libs)
set(CMAKE_SYSROOT "${ARM_TOOLCHAIN_ROOT}/arm-none-linux-gnueabihf/libc")

# ARMv7-A hard-float
set(ARM_FLAGS "-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=hard")
set(CMAKE_C_FLAGS_INIT   "${ARM_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${ARM_FLAGS}")

# Search for programs on the host, but libs/headers/packages in the sysroot only
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
