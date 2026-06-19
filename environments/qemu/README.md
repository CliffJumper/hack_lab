# QEMU Environment

This directory contains scripts and configurations to create and manage Arch Linux-based virtual machines in QEMU.

## Directory Structure

- `scripts/` - QEMU creation and management scripts
  - `create_arch_apple_silicon_macos.sh` - Creates/runs Arch Linux ARM VM for Apple Silicon Macs
  - `create_arch_x86_64_linux.sh` - Creates/runs Arch Linux VM for x86_64 Linux
- `config/` - UEFI firmware and local configuration files
- `images/` - VM disk images and installer ISOs
  - `base_images/` - Base QCOW2 virtual disks
  - `isos/` - Installation media ISOs

---

## Arch Linux VM Creation & Usage

### 1. Apple Silicon macOS
Prerequisite: Install QEMU via Homebrew:
```bash
brew install qemu
```

Run the script to build or launch the VM:
```bash
./scripts/create_arch_apple_silicon_macos.sh
```

**Workflow:**
- Select **Option 2** on first launch to boot from the Archboot ISO. **This can be used to create a base image that can be used in other scripts, or as a nearly-empty base to copy and lanuch to install tools for various custom images**.
- Follow the interactive Archboot installer (root login, run `archboot-allinone.sh`, partition `/dev/vda` with GPT, format EFI to VFAT and root to EXT4, install packages, and ensure `sshd` is enabled).
- Shutdown the VM once installation is complete, then select **Option 1** on future runs to boot natively from the disk.
- Log in via SSH: `ssh root@localhost -p 2222`

**NOTE: If you start creating various images off the base image, either view scripts/creaet_arch_apple_silicon_macos.sh for examples of how to launch them, or edit the script to add an option to launch your new custom images __I might update this script to do this in the future__**

### 2. x86_64 Linux __I HAVEN'T TESTED THIS SCRIPT YET__
Prerequisite: Install QEMU using your system's package manager:
- Arch Linux: `sudo pacman -S qemu-desktop qemu-img`
- Debian/Ubuntu: `sudo apt install qemu-system-x86 qemu-utils`

Run the script:
```bash
./scripts/create_arch_x86_64_linux.sh
```

**Workflow Options:**
- **Option 2 (Prebuilt Image - Instant):** Automatically downloads the official pre-built `arch-boxes` QCOW2 image and configures it for immediate use (default login: `arch` / `arch`).
- **Option 3 (ISO Installer):** Creates a blank disk and boots the official Arch Linux x86_64 ISO allowing custom guided installation (`archinstall`).
- **Option 1 (Run Existing):** Boots the existing disk directly using KVM hardware acceleration.
- Log in via SSH: `ssh arch@localhost -p 2222`