# Copyright (C) 2024 Your Name <your_email@example.com>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Support for Sing-Box
LUCI_DESCRIPTION:=Configuration interface for Sing-Box
LUCI_DEPENDS:=+singbox

PKG_NAME:=luci-app-singbox
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
