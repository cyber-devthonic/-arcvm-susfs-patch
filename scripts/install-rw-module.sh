#!/bin/bash
curl -L https://github.com/oscarchang1030/APatch/releases/download/v0.9.2/system_rw_overlayfs.zip -o /tmp/rw.zip
adb push /tmp/rw.zip /sdcard/Download/
echo "Install via KernelSU Manager → Enables RW /system"
