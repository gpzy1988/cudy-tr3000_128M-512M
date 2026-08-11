#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default

# Copy custom local packages into OpenWrt tree so they are available during build
if [ -d "$GITHUB_WORKSPACE/package/luci-compat-keep" ]; then
  mkdir -p package
  cp -r "$GITHUB_WORKSPACE/package/luci-compat-keep" package/
fi

# ============================================================
# 软件源配置 (在 feeds update 之前执行, 只修改 feeds 定义)
# ============================================================

# istore 应用商店 (提供大量可直接安装的软件包)
echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default

# 社区常用插件集: kenzo (常用插件) + small (ssr/passwall 等依赖)
# 提供 passwall/passwall2/ssr-plus/homeproxy/mihomo/mosdns 等常用插件及其完整依赖
echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >> feeds.conf.default
echo 'src-git small https://github.com/kenzok8/small' >> feeds.conf.default

# ============================================================
# 直接克隆到 package/ 目录的插件 (优先级高于 feeds, 各版本通用)
# ============================================================

# Aurora 主题及配置
git clone --depth 1 https://github.com/eamonxg/luci-theme-aurora package/luci-theme-aurora
git clone --depth 1 https://github.com/eamonxg/luci-app-aurora-config package/luci-app-aurora-config

# Bandix 带宽管理
git clone --depth 1 https://github.com/timsaya/luci-app-bandix package/luci-app-bandix
git clone --depth 1 https://github.com/timsaya/openwrt-bandix package/openwrt-bandix

# OpenClash 科学上网 GUI (自包含依赖, 冲突最少)
git clone --depth 1 https://github.com/vernesong/OpenClash package/luci-app-openclash 2>/dev/null || true

# Argon 主题 (社区最常用主题, 适配 23.05+)
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon 2>/dev/null || true
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config 2>/dev/null || true
