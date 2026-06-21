#!/bin/bash
# Build RPi4 UEFI firmware on macOS. Usage: ./build_rpi4.sh [DEBUG|RELEASE]
set -e
BUILD_TYPE="${1:-DEBUG}"
export WORKSPACE="$PWD"
export PACKAGES_PATH="$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi"
export GCC_AARCH64_PREFIX="aarch64-elf-"
export GCC5_AARCH64_PREFIX="aarch64-elf-"
export PYTHON_COMMAND="$(which python3)"
export EDK_TOOLS_PATH="$WORKSPACE/edk2/BaseTools"

PATCH_DIR="$WORKSPACE/patches-edk"
PATCH_STAMP="$WORKSPACE/edk2-platforms/.reactos_patched"
if [ -d "$PATCH_DIR" ] && [ ! -f "$PATCH_STAMP" ]; then
  echo "=== Applying edk2-platforms patches ==="
  for p in "$PATCH_DIR"/*.patch; do
    [ -e "$p" ] || continue
    echo "  applying $(basename "$p")"
    git -C "$WORKSPACE/edk2-platforms" apply --whitespace=nowarn "$p" || { echo "PATCH FAILED: $p"; exit 1; }
  done
  touch "$PATCH_STAMP"
  echo "=== patches applied ==="
else
  echo "=== edk2-platforms patches already applied; skipping ==="
fi

source edk2/edksetup.sh BaseTools

build -a AARCH64 -t GCC -b "$BUILD_TYPE" \
  -p edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc \
  -n "$(sysctl -n hw.ncpu)" \
  "${@:2}"

echo "=== BUILD DONE: $BUILD_TYPE ==="
ls -la "Build/RPi4/${BUILD_TYPE}_GCC/FV/RPI_EFI.fd" 2>/dev/null && echo "FD PRODUCED" || echo "NO FD"
