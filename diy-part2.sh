#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# ============================================================
# kenzo/small 与官方 feeds 冲突处理 (各版本通用, 失败不中断)
# 说明: kenzo/small 提供最新版插件, 需移除官方 feeds 中的同名旧包
# ============================================================
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray,v2ray,sing,smartdns} 2>/dev/null
rm -rf feeds/packages/utils/v2dat 2>/dev/null
rm -rf feeds/luci/applications/luci-app-mosdns 2>/dev/null
# 替换为较新的 golang (ssr/passwall 等插件依赖新版 golang 构建)
rm -rf feeds/packages/lang/golang 2>/dev/null
git clone --depth 1 https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang 2>/dev/null || true

# Enable USB power for Cudy TR3000 by default
sed -i '/modem-power/,/};/{s/gpio-export,output = <1>;/gpio-export,output = <0>;/}' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1.dtsi

# ============================================================
# Cudy TR3000 512MB NAND 设备适配
# ============================================================
DTS_DIR="target/linux/mediatek/dts"

# 复制 DTS 和 DTSI 文件 (源文件存在时才执行, 兼容不同版本路径)
if [ -f "$DTS_DIR/mt7981b-cudy-tr3000-v1.dts" ]; then
  cp "$DTS_DIR/mt7981b-cudy-tr3000-v1.dts" "$DTS_DIR/mt7981b-cudy-tr3000-512mb-v1.dts"
  cp "$DTS_DIR/mt7981b-cudy-tr3000-v1.dtsi" "$DTS_DIR/mt7981b-cudy-tr3000-512mb-v1.dtsi"

  # 修改 NAND 容量 (512MB = 0x20000000 字节)
  # 注意：0x5c0000 是前面引导区偏移，0x20000000 - 0x5c0000 = 0x1FA40000 可用空间
  sed -i 's|reg = <0x5c0000 0x4000000>;|reg = <0x5c0000 0x1FA40000>;|' "$DTS_DIR/mt7981b-cudy-tr3000-512mb-v1.dts"

  # 更新 partition 表中 UBI 分区定义
  sed -i -e '/partition@5c0000 {/,/^[ \t]*};/ {
      s|compatible = "linux,ubi";|reg = <0x5c0000 0x1FA40000>;\n\t\tcompatible = "linux,ubi";|
  }' "$DTS_DIR/mt7981b-cudy-tr3000-512mb-v1.dtsi"
fi

# 注册新设备定义 (已注册则跳过, 避免重复执行时冲突)
if ! grep -q "cudy_tr3000-512mb-v1" target/linux/mediatek/image/filogic.mk 2>/dev/null; then
  sed -i '/TARGET_DEVICES/ a \
define Device/cudy_tr3000-512mb-v1 \
  DEVICE_VENDOR := Cudy \
  DEVICE_MODEL := TR3000 \
  DEVICE_VARIANT := v1 (512MB NAND) \
  DEVICE_DTS := mt7981b-cudy-tr3000-512mb-v1 \
  DEVICE_DTS_DIR := ../dts \
  SUPPORTED_DEVICES += R47-512MB \
  UBINIZE_OPTS := -E 5 \
  BLOCKSIZE := 128k \
  PAGESIZE := 2048 \
  IMAGE_SIZE := 507904k \
  KERNEL_IN_UBI := 1 \
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata \
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware automount \
endef \
TARGET_DEVICES += cudy_tr3000-512mb-v1
' target/linux/mediatek/image/filogic.mk
fi

