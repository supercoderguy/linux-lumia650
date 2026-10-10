#!/usr/bin/env bash
# Build Lumia650Pkg (EDK2 UEFI for the Lumia 650) as emmc_appsboot.mbn, the ELF
# that BootShim loads from EFIESP.
#
# Needs: arm-none-eabi-gcc, gcc/g++, make, nasm, python3, libuuid headers.
# Works with GCC 16 and Python 3.14 thanks to the patches in ./patches.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${WORK:-$HERE/../../edk2-lumia650}"
CROSS="${CROSS:-arm-none-eabi-}"

if [ ! -d "$WORK" ]; then
    git clone --depth 1 -b stable/202011 --recurse-submodules --shallow-submodules \
        https://github.com/tianocore/edk2.git "$WORK"
    git clone --depth 1 https://github.com/sonic011gamer/Lumia650Pkg "$WORK/Lumia650Pkg"
    git -C "$WORK" apply "$HERE/patches/edk2-202011-python3.14.patch"
    git -C "$WORK/Lumia650Pkg" apply "$HERE/patches/lumia650pkg.patch"
fi

cd "$WORK"
# GCC 15+ defaults to C23, which breaks 2020-era BaseTools code; build as gnu17.
make -C BaseTools/Source/C -j"$(nproc)" \
    CC="gcc -std=gnu17" BUILD_CC="gcc -std=gnu17" \
    CXX="g++ -std=gnu++14" BUILD_CXX="g++ -std=gnu++14" EXTRA_OPTFLAGS="-Wno-error"

export PYTHON_COMMAND=python3
set +u; . ./edksetup.sh >/dev/null; set -u
GCC5_ARM_PREFIX="$CROSS" build -a ARM -p Lumia650Pkg/Lumia650.dsc -t GCC5 -j"$(nproc)" -s -n 0

FV=Build/Lumia650-ARM/DEBUG_GCC5/FV
"${CROSS}objcopy" -I binary -O elf32-littlearm --binary-architecture arm \
    "$FV/MSM8909_EFI.fd" "$FV/MSM8909_EFI.fd.elf"
"${CROSS}ld" "$FV/MSM8909_EFI.fd.elf" -T Lumia650Pkg/FvWrapper.ld -o emmc_appsboot.mbn
echo "Built $WORK/emmc_appsboot.mbn"
