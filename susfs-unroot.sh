#!/bin/bash
echo -e "\e[1;33m=== ARCVM Full Unroot (SUSFS + OverlayFS + KernelSU) ===\e[0m"
curl -Ls https://raw.githubusercontent.com/supechicken/ChromeOS-ARCVM-Root/main/unroot.sh | sudo bash -eu
