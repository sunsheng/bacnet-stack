# CMake toolchain file: Windows x64 (64-bit) via MinGW-w64
# Toolchain: x86_64-w64-mingw32 (GCC 13), cross-compiling from Linux
# Static link so the .exe runs without libgcc/winpthread DLLs.
#
# Usage:
#   cmake -B build-win64 \
#     -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw-x86_64.cmake \
#     -DCMAKE_BUILD_TYPE=Release
#   cmake --build build-win64 -j

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)

set(TOOLCHAIN_PREFIX x86_64-w64-mingw32)

set(CMAKE_C_COMPILER   ${TOOLCHAIN_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}-g++)
set(CMAKE_RC_COMPILER  ${TOOLCHAIN_PREFIX}-windres)
set(CMAKE_AR           ${TOOLCHAIN_PREFIX}-ar)
set(CMAKE_RANLIB       ${TOOLCHAIN_PREFIX}-ranlib)

# Statically link runtime so the produced .exe is standalone
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static -static-libgcc")

set(CMAKE_FIND_ROOT_PATH /usr/${TOOLCHAIN_PREFIX})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
