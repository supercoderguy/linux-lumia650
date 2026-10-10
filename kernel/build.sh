#!/usr/bin/env bash
# Build the Lumia 650 kernel (zImage with built-in debug initramfs) and dtb,
# and copy them to deploy/linux/.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$HERE/.."
KSRC="${KSRC:-$REPO/../linux-msm8909}"
CROSS="${CROSS:-arm-none-eabi-}"
MAKE=(make -C "$KSRC" ARCH=arm CROSS_COMPILE="$CROSS" O=build -j"$(nproc)")

BUSYBOX_URL=https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-armv7l
BUSYBOX_SHA256=cd04052b8b6885f75f50b2a280bfcbf849d8710c8e61d369c533acf307eda064

if [ ! -d "$KSRC" ]; then
    git clone --depth 1 https://github.com/msm8916-mainline/linux.git "$KSRC"
fi

# Device tree
cp "$HERE/dts/qcom-msm8909-microsoft-saana.dts" "$KSRC/arch/arm/boot/dts/qcom/"
grep -q 'qcom-msm8909-microsoft-saana.dtb' "$KSRC/arch/arm/boot/dts/qcom/Makefile" ||
    sed -i 's/^\tqcom-msm8909-nokia-leo.dtb \\$/\tqcom-msm8909-microsoft-saana.dtb \\\n&/' \
        "$KSRC/arch/arm/boot/dts/qcom/Makefile"

# Initramfs: static busybox + our /init
BB="$REPO/initramfs/busybox"
if ! echo "$BUSYBOX_SHA256  $BB" | sha256sum -c --status 2>/dev/null; then
    curl -sfL -o "$BB" "$BUSYBOX_URL"
    echo "$BUSYBOX_SHA256  $BB" | sha256sum -c
fi
cat > "$REPO/initramfs/initramfs.list" <<EOF
dir /dev 0755 0 0
nod /dev/console 0600 0 0 c 5 1
dir /bin 0755 0 0
file /bin/busybox $BB 0755 0 0
slink /bin/sh busybox 0777 0 0
file /init $REPO/initramfs/init 0755 0 0
EOF

# Config: msm8916_defconfig (arm64 base + arm part) + our fragment
cat "$KSRC/arch/arm64/configs/msm8916_defconfig" "$KSRC/arch/arm/configs/msm8916_defconfig.part" \
    > "$KSRC/arch/arm/configs/msm8916_defconfig"
"${MAKE[@]}" -s msm8916_defconfig
"$KSRC/scripts/kconfig/merge_config.sh" -m -O "$KSRC/build" "$KSRC/build/.config" "$HERE/lumia650.config" >/dev/null
"$KSRC/scripts/config" --file "$KSRC/build/.config" --set-str INITRAMFS_SOURCE "$REPO/initramfs/initramfs.list"
"${MAKE[@]}" -s olddefconfig

"${MAKE[@]}" -s zImage qcom/qcom-msm8909-microsoft-saana.dtb 2>&1 | grep -v -E 'Warning|also defined at' || true

mkdir -p "$REPO/deploy/linux"
cp "$KSRC/build/arch/arm/boot/zImage" "$REPO/deploy/linux/zImage"
cp "$KSRC/build/arch/arm/boot/dts/qcom/qcom-msm8909-microsoft-saana.dtb" "$REPO/deploy/linux/saana.dtb"
(cd "$REPO/deploy" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
echo "Built deploy/linux/zImage and deploy/linux/saana.dtb"
