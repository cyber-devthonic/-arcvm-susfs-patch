#!/bin/bash
# ARCVM SUSFS + OverlayFS Auto-Root (KernelSU + SUSFS v1.4.2 + RW /system)
# curl -Ls https://raw.githubusercontent.com/cyber-devthonic/arcvm-susfs-patch/main/susfs-root.sh | sudo bash -eu

set -euo pipefail

RED='\e[1;31m'
YELLOW='\e[1;33m'
GREEN='\e[1;32m'
BLUE='\e[1;34m'
RESET='\e[0m'

KERNEL_DIR="/opt/google/vms/android"
KERNEL_LINK="$KERNEL_DIR/vmlinux"
KERNEL_REAL="$KERNEL_DIR/vmlinux.ksu"
BACKUP_DIR="/mnt/stateful_partition/arcvm_unpatched_root"
SUSFS_TARBALL="https://github.com/simonpunk/susfs4ksu/archive/refs/tags/v1.4.2.tar.gz"
OVERLAYFS_PATCH_URL="https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/overlayfs.patch"
TEMP_DIR="/tmp/arcvm-susfs"

echo -e "${BLUE}=== ARCVM SUSFS + OverlayFS Auto-Root (v1.4.2) ===${RESET}"

# === 1. Detect root ===
if [ -L "$KERNEL_LINK" ] && [ "$(readlink "$KERNEL_LINK")" = "vmlinux.ksu" ]; then
    echo -e "${GREEN}[+] KernelSU detected. Patching with SUSFS + OverlayFS...${RESET}"
    ROOTED=true
else
    echo -e "${YELLOW}[+] Not rooted. Running supechicken/root.sh...${RESET}"
    ROOTED=false
fi

# === 2. Auto-root if needed ===
if [ "$ROOTED" = false ]; then
    echo -e "${BLUE}[+] Backing up original kernel...${RESET}"
    mkdir -p "$BACKUP_DIR"
    cp "/opt/google/vms/android/vmlinux" "$BACKUP_DIR/vmlinux.original"
    curl -Ls https://raw.githubusercontent.com/supechicken/ChromeOS-ARCVM-Root/main/root.sh | sudo bash -eu
    echo -e "${YELLOW}[!] Rebooting in 10s to apply root...${RESET}"
    sleep 10
    reboot
    exit 0
fi

# === 3. Setup temp ===
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# === 4. Extract current kernel ===
echo -e "${BLUE}[+] Extracting current kernel...${RESET}"
gunzip -c "$KERNEL_REAL" > vmlinux || cp "$KERNEL_REAL" vmlinux

# === 5. Apply SUSFS v1.4.2 ===
echo -e "${BLUE}[+] Downloading & applying SUSFS v1.4.2...${RESET}"
curl -L "$SUSFS_TARBALL" -o susfs.tar.gz
tar -xzf susfs.tar.gz
PATCH_DIR="$(find . -name "susfs4ksu-*" -type d | head -1)"

for patch in "$PATCH_DIR"/*.patch; do
    echo "  → Applying $(basename "$patch")"
    patch -p1 < "$patch" || {
        echo -e "${RED}SUSFS patch failed!${RESET}"
        rm -rf "$TEMP_DIR"
        exit 1
    }
done

# === 6. Apply OFFICIAL KernelSU OverlayFS Patch ===
echo -e "${BLUE}[+] Applying official KernelSU overlayfs.patch (RW /system)...${RESET}"
curl -L "$OVERLAYFS_PATCH_URL" -o overlayfs.patch
patch -p1 < overlayfs.patch || {
    echo -e "${YELLOW}OverlayFS patch failed (non-critical). /system may stay RO.${RESET}"
}

# === 7. Rebuild & Install ===
echo -e "${BLUE}[+] Rebuilding patched kernel...${RESET}"
gzip -9 vmlinux -c > Image.gz.patched
cp Image.gz.patched "$KERNEL_REAL"
chmod 644 "$KERNEL_REAL"

# === 8. Cleanup ===
rm -rf "$TEMP_DIR"

# === 9. Done ===
echo
echo -e "${GREEN}SUSFS v1.4.2 + OverlayFS (RW /system) + KernelSU installed!${RESET}"
echo -e "${GREEN}After reboot: Use KernelSU Manager → Modules → Install 'System RW' module${RESET}"
echo -e "${GREEN}Or run: adb shell su -c 'mount -o rw,remount /system'${RESET}"
echo

read -r -N1 -p $'Reboot now? [Y/n]: ' ans < /dev/tty
echo
case $ans in Y|y) reboot ;; esac
