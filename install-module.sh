#!/bin/bash
echo "Installing SUSFS + System RW modules..."

# SUSFS Module
curl -L https://github.com/ravindu644/ksu_module_susfs/releases/download/v1.4.2/ksu_module_susfs-v1.4.2.zip -o /tmp/susfs.zip
adb push /tmp/susfs.zip /sdcard/Download/

# System RW Module
curl -L https://github.com/oscarchang1030/APatch/releases/download/v0.9.2/system_rw_overlayfs.zip -o /tmp/rw.zip
adb push /tmp/rw.zip /sdcard/Download/

echo "Open KernelSU Manager → Modules → Install both ZIPs"
