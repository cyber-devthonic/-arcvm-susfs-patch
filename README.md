# ARCVM SUSFS + OverlayFS Patch (KernelSU + RW /system)

**One command. Full root hiding + systemless `/system` read-write.**

```bash
curl -Ls https://raw.githubusercontent.com/cyber-devthonic/arcvm-susfs-patch/main/susfs-root.sh | sudo bash -eu
```

---

## Features

- Auto-detects **non-rooted** ARCVM → runs `supechicken/root.sh`
- Patches **existing kernel** with **SUSFS v1.4.2** (root hiding)
- Applies **official KernelSU OverlayFS patch** → **RW `/system`**
- Full **unroot** with `susfs-unroot.sh`
- No source. No build. **< 15 seconds**
- Safe, reversible, persistent

---

## One-Liner Commands

| Action | Command |
|-------|--------|
| **Root + SUSFS + RW** | `curl -Ls https://raw.githubusercontent.com/cyber-devthonic/arcvm-susfs-patch/main/susfs-root.sh \| sudo bash -eu` |
| **Unroot** | `curl -Ls https://raw.githubusercontent.com/cyber-devthonic/arcvm-susfs-patch/main/susfs-unroot.sh \| sudo bash -eu` |

---

## After Root

```bash
# Install SUSFS + RW modules
./install-module.sh
```

---

## Verify

```bash
./verify.sh
```

---

## Credits

- [supechicken/ChromeOS-ARCVM-Root](https://github.com/supechicken/ChromeOS-ARCVM-Root)
- [simonpunk/susfs4ksu](https://github.com/simonpunk/susfs4ksu)
- [tiann/KernelSU](https://github.com/tiann/KernelSU)
