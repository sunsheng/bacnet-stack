#!/usr/bin/env bash
#
# Local armhf (32-bit ARM hard-float) cross build for Windows, run from Git Bash.
#
# Mirrors .github/workflows/gcc.yml but builds on a native Windows host:
#   - no WSL, no Docker, no MSYS2 package manager
#   - uses the already-installed Git Bash for the POSIX shell + coreutils
#   - a prebuilt Windows-hosted (mingw-w64-i686) Arm cross toolchain, glibc 2.31
#   - a standalone Windows GNU make binary (ezwinports)
#
# Why these exact downloads:
#   The target device runs armhf userspace with glibc 2.31. A binary linked
#   against a newer glibc fails on-device ("GLIBC_2.34 not found"). The Arm GNU
#   Toolchain 10.2-2020.11 ships glibc 2.31, so binaries need only GLIBC <= 2.31.
#   That release's ONLY Windows host package is mingw-w64-i686 (32-bit host); it
#   runs fine on 64-bit Windows via WOW64 and still emits armhf-Linux ELF.
#
# Download URLs (place the archives in $ARM_DIR, or let this script fetch them):
#   Toolchain (134 MB):
#     https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-mingw-w64-i686-arm-none-linux-gnueabihf.tar.xz
#   GNU make (ezwinports, standalone w32 binary):
#     https://downloads.sourceforge.net/project/ezwinports/make-4.4.1-without-guile-w32-bin.zip
#
# Usage (from Git Bash):
#   tools/build-armhf-windows.sh            # clean + build BBMD=client apps
#   ARM_DIR=/d/arm tools/build-armhf-windows.sh
#
set -euo pipefail

# --- configuration -----------------------------------------------------------
ARM_DIR="${ARM_DIR:-/e/arm}"                 # where archives are / get extracted
TC_DIR="$ARM_DIR/toolchain"                  # extracted toolchain root
MAKE_DIR="$ARM_DIR/make"                     # extracted make root
CROSS="arm-none-linux-gnueabihf"
CPU="${CPU:-cortex-a53}"                     # device is Cortex-A53
BBMD="${BBMD:-client}"
BACDL="${BACDL:-bip}"

TC_URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-mingw-w64-i686-${CROSS}.tar.xz"
MAKE_URL="https://downloads.sourceforge.net/project/ezwinports/make-4.4.1-without-guile-w32-bin.zip"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }

# --- toolchain ---------------------------------------------------------------
if [ ! -x "$TC_DIR/bin/${CROSS}-gcc" ] && [ ! -x "$TC_DIR/bin/${CROSS}-gcc.exe" ]; then
  log "Toolchain not extracted; locating archive in $ARM_DIR"
  tc_tar="$(ls "$ARM_DIR"/gcc-arm-*mingw-w64-i686-${CROSS}.tar.xz 2>/dev/null | head -1 || true)"
  if [ -z "$tc_tar" ]; then
    log "Downloading toolchain (134 MB)"
    tc_tar="$ARM_DIR/gcc-arm-10.2-2020.11-mingw-w64-i686-${CROSS}.tar.xz"
    mkdir -p "$ARM_DIR"
    curl -fSL --retry 3 --retry-delay 5 "$TC_URL" -o "$tc_tar"
  fi
  log "Extracting $(basename "$tc_tar")"
  mkdir -p "$TC_DIR"
  tar -xf "$tc_tar" -C "$TC_DIR" --strip-components=1
fi

# --- make --------------------------------------------------------------------
MAKE_BIN_DIR="$MAKE_DIR/bin"
if [ ! -x "$MAKE_BIN_DIR/make.exe" ]; then
  log "make not extracted; locating archive in $ARM_DIR"
  make_zip="$(ls "$ARM_DIR"/make-*w32-bin*.zip 2>/dev/null | head -1 || true)"
  if [ -z "$make_zip" ]; then
    log "Downloading GNU make (ezwinports)"
    make_zip="$ARM_DIR/make-4.4.1-without-guile-w32-bin.zip"
    mkdir -p "$ARM_DIR"
    curl -fSL --retry 3 --retry-delay 5 "$MAKE_URL" -o "$make_zip"
  fi
  log "Extracting $(basename "$make_zip")"
  mkdir -p "$MAKE_DIR"
  unzip -q -o "$make_zip" -d "$MAKE_DIR"
fi

# --- build -------------------------------------------------------------------
# Put the cross toolchain first (provides ${CROSS}-gcc/-ar/-size) and the
# standalone make on PATH. Git Bash already supplies sh/rm/cp; GNU make
# auto-detects /usr/bin/sh, so the Makefile's `( cd .. ; .. )` recipes work.
export PATH="$TC_DIR/bin:$MAKE_BIN_DIR:$PATH"

log "Toolchain: $(${CROSS}-gcc --version | head -1)"
log "make:      $(make --version | head -1)"

cd "$REPO_ROOT"

log "make clean"
# `clean` recurses into every port, incl. microcontroller ports (atmega328 etc.)
# whose toolchains (avr-gcc) are absent here; those clean steps print harmless
# 'command not found' to stderr and are ignored. Don't let that abort us.
make clean || true

log "Building BBMD=$BBMD BACDL=$BACDL apps for $CROSS (-mcpu=$CPU)"
# BACNET_PORT=linux is forced: on a Windows host the apps Makefile would
# otherwise auto-select the win32 (winsock) port. SIZE points at the cross
# binutils 'size' (Git Bash has no host 'size').
make LEGACY=true BBMD="$BBMD" BACDL="$BACDL" BACNET_PORT=linux \
  CC="${CROSS}-gcc -mcpu=${CPU}" \
  AR="${CROSS}-ar" \
  SIZE="${CROSS}-size" \
  all

# --- collect + verify --------------------------------------------------------
log "Collecting armhf ELF binaries into artifacts/"
rm -rf artifacts && mkdir -p artifacts
count=0
for f in bin/*; do
  if [ -f "$f" ] && file "$f" | grep -q "ELF 32-bit.*ARM"; then
    cp "$f" artifacts/
    count=$((count + 1))
  fi
done
log "Collected $count armhf ELF binaries:"
file artifacts/* || true

log "Done. Binaries in $REPO_ROOT/artifacts/"
