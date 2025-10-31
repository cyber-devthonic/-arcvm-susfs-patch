#!/bin/bash
adb shell << 'EOF'
su -c '
  echo "=== SUSFS Status ==="
  dmesg | grep -i susfs || echo "SUSFS not loaded"
  ksu_susfs --status 2>/dev/null || echo "ksu_susfs not found"

  echo "=== OverlayFS /system RW ==="
  mount | grep "overlay on /system" && echo "/system is RW (overlay)" || echo "/system is RO"
'
EOF
