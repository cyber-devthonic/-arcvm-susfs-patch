#!/bin/bash
curl -L https://github.com/ravindu644/ksu_module_susfs/releases/download/v1.4.2/ksu_module_susfs-v1.4.2.zip -o /tmp/susfs.zip
adb push /tmp/susfs.zip /sdcard/Download/
echo "Install via KernelSU Manager"
