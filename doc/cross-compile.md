# 交叉编译指南（5 套目标）

本文档说明如何用 CMake 把 bacnet-stack 交叉编译到以下 5 个目标平台。
所有 CMake 工具链文件位于 `cmake/` 目录，彼此独立，可单独使用。

> CI：`.github/workflows/cross-build.yml` 会自动构建全部 5 个目标；推送 `v*`
> 标签时把打包好的二进制作为 GitHub Release 资产发布。

| # | 目标平台 | 工具链 | libc / 运行时 | 链接方式 | 构建目录 |
|---|---|---|---|---|---|
| 1 | Linux ARM32 (armhf) | Arm GNU-A 10.2-2020.11 | glibc 2.31 | 动态 | `build-arm32/` |
| 2 | Linux ARM32 (armhf) | musl.cc arm-linux-musleabihf | musl | **完全静态** | `build-arm32-musl/` |
| 3 | Linux x86_64 | musl.cc x86_64-linux-musl | musl | **完全静态** | `build-linux-x86_64-musl/` |
| 4 | Windows x86 (32 位) | MinGW-w64 i686 | msvcrt | 静态 | `build-win32/` |
| 5 | Windows x64 (64 位) | MinGW-w64 x86_64 | msvcrt | 静态 | `build-win64/` |

> ARM 目标均为 ARMv7-A 硬浮点（`-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=hard`）。
> Windows 两套各 47 个程序（`modbusgw` 在 MinGW 下由 CMake 自动跳过），Linux 两套各 48 个。

---

## 0. 通用前置

```bash
sudo apt-get update
sudo apt-get install -y cmake
```

每个目标都在独立的构建目录里 `out-of-source` 构建，互不影响。
所有命令在仓库根目录执行。

---

## 1. Linux ARM32 — glibc 2.31（动态）

适用：目标设备 glibc ≥ 2.31（如 Ubuntu 20.04 ARM 根文件系统）。体积小。

### 准备工具链（一次性）

```bash
sudo mkdir -p /opt/arm-gnu && sudo chown "$(id -u):$(id -g)" /opt/arm-gnu
cd /opt/arm-gnu
curl -L -o gcc-arm-10.2.tar.xz \
  "https://developer.arm.com/-/media/files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf.tar.xz"
tar xf gcc-arm-10.2.tar.xz
```

工具链根目录：`/opt/arm-gnu/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf`
（与工具链文件中的默认值一致；如放别处用 `-DARM_TOOLCHAIN_ROOT=...` 覆盖。）

### 构建

```bash
export PATH=/opt/arm-gnu/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf/bin:$PATH
cmake -B build-arm32 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-linux-gnueabihf.cmake \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build-arm32 -j"$(nproc)"
```

### 验证

```bash
file build-arm32/whois
# ELF 32-bit LSB executable, ARM, EABI5, dynamically linked,
# interpreter /lib/ld-linux-armhf.so.3
```

---

## 2. Linux ARM32 — musl（完全静态）

适用：任意 ARM Linux，**零 libc 依赖**，与目标 glibc/musl 版本无关。最佳可移植性。

### 准备工具链（一次性）

```bash
cd /opt/arm-gnu
curl -L -o arm-linux-musleabihf-cross.tgz \
  "https://musl.cc/arm-linux-musleabihf-cross.tgz"
tar xf arm-linux-musleabihf-cross.tgz
```

工具链根目录：`/opt/arm-gnu/arm-linux-musleabihf-cross`
（如放别处用 `-DARM_MUSL_TOOLCHAIN_ROOT=...` 覆盖。）

### 构建

```bash
export PATH=/opt/arm-gnu/arm-linux-musleabihf-cross/bin:$PATH
cmake -B build-arm32-musl \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-musl-static.cmake \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build-arm32-musl -j"$(nproc)"
```

### 验证

```bash
file build-arm32-musl/whois
# ELF 32-bit LSB pie executable, ARM, EABI5, static-pie linked
#  → 无 NEEDED 外部库、无动态加载器，任意 ARM Linux 直接运行
```

---

## 3. Linux x86_64 — musl（完全静态）

适用：任意 x86_64 Linux，**零 libc 依赖**，与目标 glibc 版本无关。

### 准备工具链（一次性）

```bash
cd /opt/arm-gnu
curl -L -o x86_64-linux-musl-cross.tgz \
  "https://musl.cc/x86_64-linux-musl-cross.tgz"
tar xf x86_64-linux-musl-cross.tgz
```

工具链根目录：`/opt/arm-gnu/x86_64-linux-musl-cross`
（如放别处用 `-DX86_64_MUSL_TOOLCHAIN_ROOT=...` 覆盖。）

### 构建

```bash
export PATH=/opt/arm-gnu/x86_64-linux-musl-cross/bin:$PATH
cmake -B build-linux-x86_64-musl \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-x86_64-musl-static.cmake \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build-linux-x86_64-musl -j"$(nproc)"
```

### 验证

```bash
file build-linux-x86_64-musl/whois
# ELF 64-bit LSB pie executable, x86-64, static-pie linked
#  → 无外部依赖，任意 x86_64 Linux 直接运行
```

---

## 4. Windows x86（32 位）

### 准备工具链（一次性）

```bash
sudo apt-get install -y gcc-mingw-w64-i686
```

### 构建

```bash
cmake -B build-win32 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw-i686.cmake \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build-win32 -j"$(nproc)"
```

### 验证

```bash
file build-win32/whois.exe
# PE32 executable (console) Intel 80386, for MS Windows
#  → 仅依赖系统 DLL，无 libgcc/winpthread DLL（已静态链接）
```

---

## 5. Windows x64（64 位）

### 准备工具链（一次性）

```bash
sudo apt-get install -y gcc-mingw-w64-x86-64
```

### 构建

```bash
cmake -B build-win64 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw-x86_64.cmake \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build-win64 -j"$(nproc)"
```

### 验证

```bash
file build-win64/whois.exe
# PE32+ executable (console) x86-64, for MS Windows
#  → 仅依赖系统 DLL，无 libgcc/winpthread DLL（已静态链接）
```

---

## 一键编译全部 5 个目标

```bash
#!/bin/sh
set -e
ARM_GNU=/opt/arm-gnu/gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf
ARM_MUSL=/opt/arm-gnu/arm-linux-musleabihf-cross
X64_MUSL=/opt/arm-gnu/x86_64-linux-musl-cross

# 1) Linux ARM32 glibc（动态）
PATH="$ARM_GNU/bin:$PATH" cmake -B build-arm32 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-linux-gnueabihf.cmake -DCMAKE_BUILD_TYPE=Release
PATH="$ARM_GNU/bin:$PATH" cmake --build build-arm32 -j"$(nproc)"

# 2) Linux ARM32 musl（静态）
PATH="$ARM_MUSL/bin:$PATH" cmake -B build-arm32-musl \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-musl-static.cmake -DCMAKE_BUILD_TYPE=Release
PATH="$ARM_MUSL/bin:$PATH" cmake --build build-arm32-musl -j"$(nproc)"

# 3) Linux x86_64 musl（静态）
PATH="$X64_MUSL/bin:$PATH" cmake -B build-linux-x86_64-musl \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-x86_64-musl-static.cmake -DCMAKE_BUILD_TYPE=Release
PATH="$X64_MUSL/bin:$PATH" cmake --build build-linux-x86_64-musl -j"$(nproc)"

# 4) Windows x86
cmake -B build-win32 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw-i686.cmake -DCMAKE_BUILD_TYPE=Release
cmake --build build-win32 -j"$(nproc)"

# 5) Windows x64
cmake -B build-win64 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw-x86_64.cmake -DCMAKE_BUILD_TYPE=Release
cmake --build build-win64 -j"$(nproc)"
```

---

## 常用可选项

- 减小体积（strip）：在工具链对应的 `*-strip` 上执行，或加 `-DCMAKE_BUILD_TYPE=MinSizeRel`，
  也可链接时加 `-s`（已 Release 构建可手动 `*-strip build-*/可执行文件`）。
- 裁剪程序：`-DBACNET_STACK_BUILD_APPS=OFF` 只编库；或关闭不需要的数据链路
  （如 `-DBACDL_ZIGBEE=OFF`）。
- 切换数据链路 / 端口：见仓库根 `CMakeLists.txt` 顶部的 `option(...)` 列表。
