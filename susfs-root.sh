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
SUSFS_TARBALL="https://github.com/cyber-devthonic/arcvm-susfs-patch/patches/susfs/v1.3.8/susfs4ksu.tar.gz"
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

# === 4. Extract current kernel (with format detection) ===
echo -e "${BLUE}[+] Extracting current kernel...${RESET}"
if file "$KERNEL_REAL" | grep -q "gzip compressed"; then
    echo "  → Detected gzip format, decompressing..."
    gunzip -c "$KERNEL_REAL" > vmlinux
elif file "$KERNEL_REAL" | grep -q "ELF\|Linux kernel"; then
    echo "  → Detected uncompressed kernel, copying..."
    cp "$KERNEL_REAL" vmlinux
else
    echo -e "${RED}[!] Unknown kernel format!${RESET}"
    file "$KERNEL_REAL"
    exit 1
fi

# === 5. Apply SUSFS v1.4.2 ===
echo -e "${BLUE}[+] Downloading & applying SUSFS v1.4.2...${RESET}"
if ! curl -fL "$SUSFS_TARBALL" -o susfs.tar.gz; then
    echo -e "${RED}[!] Failed to download SUSFS tarball${RESET}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Verify the downloaded file is actually a gzip file
if ! file susfs.tar.gz | grep -q "gzip compressed"; then
    echo -e "${RED}[!] Downloaded file is not gzip format:${RESET}"
    file susfs.tar.gz
    echo -e "${YELLOW}[!] URL may be redirecting or returning HTML error page${RESET}"
    head -20 susfs.tar.gz
    rm -rf "$TEMP_DIR"
    exit 1
fi

tar -xzf susfs.tar.gz
PATCH_DIR="$(find . -name "susfs4ksu-*" -type d | head -1)"

if [ -z "$PATCH_DIR" ] || [ ! -d "$PATCH_DIR" ]; then
    echo -e "${RED}[!] SUSFS patch directory not found after extraction${RESET}"
    ls -la
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "  → Found patch directory: $PATCH_DIR"

# Check if patches exist
if ! ls "$PATCH_DIR"/*.patch 1> /dev/null 2>&1; then
    echo -e "${RED}[!] No .patch files found in $PATCH_DIR${RESET}"
    ls -la "$PATCH_DIR"
    rm -rf "$TEMP_DIR"
    exit 1
fi

for patch in "$PATCH_DIR"/*.patch; do
    echo "  → Applying $(basename "$patch")"
    if ! patch -p1 < "$patch"; then
        echo -e "${RED}[!] SUSFS patch failed: $(basename "$patch")${RESET}"
        echo -e "${YELLOW}[!] This may be because patches are already applied or incompatible${RESET}"
        # Don't exit immediately, try to continue
    fi
done

# === 6. Apply OFFICIAL KernelSU OverlayFS Patch ===
echo -e "${BLUE}[+] Applying official KernelSU overlayfs.patch (RW /system)...${RESET}"
if curl -fL "$OVERLAYFS_PATCH_URL" -o overlayfs.patch; then
    if ! patch -p1 < overlayfs.patch; then
        echo -e "${YELLOW}[!] OverlayFS patch failed (non-critical). /system may stay RO.${RESET}"
    fi
else
    echo -e "${YELLOW}[!] Failed to download OverlayFS patch (non-critical)${RESET}"
fi

# === 7. Rebuild & Install ===
echo -e "${BLUE}[+] Rebuilding patched kernel...${RESET}"
if [ ! -f vmlinux ]; then
    echo -e "${RED}[!] vmlinux file missing!${RESET}"
    exit 1
fi

gzip -9 vmlinux -c > Image.gz.patched

# Backup current kernel before replacing
cp "$KERNEL_REAL" "$KERNEL_REAL.backup.$(date +%s)"
cp Image.gz.patched "$KERNEL_REAL"
chmod 644 "$KERNEL_REAL"

# === 8. Cleanup ===
rm -rf "$TEMP_DIR"

# === 9. Done ===
echo
echo -e "${GREEN}✓ SUSFS v1.4.2 + OverlayFS (RW /system) + KernelSU installed!${RESET}"
echo -e "${GREEN}✓ After reboot: Use KernelSU Manager → Modules → Install 'System RW' module${RESET}"
echo -e "${GREEN}✓ Or run: adb shell su -c 'mount -o rw,remount /system'${RESET}"
echo

read -r -N1 -p $'Reboot now? [Y/n]: ' ans < /dev/tty
echo
case $ans in Y|y) reboot ;; esac
