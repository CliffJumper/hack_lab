#!/usr/bin/env bash

# create_arch_apple_silicon_macos.sh
# Creates and runs an Arch Linux ARM VM on Apple Silicon (arm64) macOS.

set -euo pipefail

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ISO_DIR="$QEMU_DIR/images/isos"
IMAGE_DIR="$QEMU_DIR/images/base_images"
CONFIG_DIR="$QEMU_DIR/config"

# Ensure directories exist
mkdir -p "$ISO_DIR" "$IMAGE_DIR" "$CONFIG_DIR"

# Validate Host System
OS="$(uname -s)"
ARCH="$(uname -m)"

if [[ "$OS" != "Darwin" ]]; then
    echo "Error: This script is intended to run on macOS (Darwin), but detected: $OS" >&2
    exit 1
fi

if [[ "$ARCH" != "arm64" ]]; then
    echo "Error: This script is designed for Apple Silicon (arm64) Macs, but detected: $ARCH" >&2
    exit 1
fi

# Verify QEMU dependencies
if ! command -v qemu-system-aarch64 &>/dev/null || ! command -v qemu-img &>/dev/null; then
    echo "Error: qemu-system-aarch64 and/or qemu-img are not installed." >&2
    echo "Please install QEMU via Homebrew:" >&2
    echo "  brew install qemu" >&2
    exit 1
fi

# Find UEFI Firmware
EFI_FIRMWARE=""
STANDARD_BREW_PATHS=(
    "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
    "/usr/local/share/qemu/edk2-aarch64-code.fd"
)

for path in "${STANDARD_BREW_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        EFI_FIRMWARE="$path"
        break
    fi
done

if [[ -z "$EFI_FIRMWARE" ]]; then
    echo "Warning: Could not find UEFI firmware 'edk2-aarch64-code.fd' at standard paths." >&2
    # Check if we have a locally cached one
    LOCAL_EFI="$CONFIG_DIR/edk2-aarch64-code.fd"
    if [[ -f "$LOCAL_EFI" ]]; then
        EFI_FIRMWARE="$LOCAL_EFI"
    else
        echo "Attempting to download a compatible edk2-aarch64-code.fd firmware..." >&2
        # Download from a public QEMU source repository mirror
        if curl -sL -o "$LOCAL_EFI" "https://raw.githubusercontent.com/qemu/qemu/master/pc-bios/edk2-aarch64-code.fd"; then
            EFI_FIRMWARE="$LOCAL_EFI"
        else
            echo "Error: Failed to download edk2-aarch64-code.fd and could not find it locally." >&2
            echo "Please ensure you have QEMU installed via Homebrew, which includes UEFI files:" >&2
            echo "  brew install qemu" >&2
            exit 1
        fi
    fi
fi

DISK_IMAGE="$IMAGE_DIR/arch-mac.qcow2"
DISK_SIZE="20G"
ISO_FILE="$ISO_DIR/archboot-aarch64.iso"

# Setup Virtual Disk
if [[ ! -f "$DISK_IMAGE" ]]; then
    echo "Creating virtual disk image: $DISK_IMAGE ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
fi

# Prompt options for the user
echo "=========================================================="
echo " Arch Linux QEMU Manager (Apple Silicon / macOS)"
echo "=========================================================="
echo "Choose one of the options below:"
echo "1) Boot from installed disk (Run VM)"
echo "2) Boot from Archboot ISO (Install / Rescue VM)"
read -r -p "Enter choice [1-2]: " choice

BOOT_ISO=false
case "$choice" in
    2)
        BOOT_ISO=true
        ;;
    *)
        BOOT_ISO=false
        ;;
esac

# Download ISO if booting from ISO and it's missing
if [[ "$BOOT_ISO" = true && ! -f "$ISO_FILE" ]]; then
    echo "Resolving the latest Archboot aarch64 ISO URL..."
    ISO_NAME=$(curl -sL https://release.archboot.com/aarch64/latest/iso/ | grep -oE 'href="/aarch64/latest/iso/archboot-[^"]+-ARCH-latest-aarch64\.iso"' | head -n 1 | cut -d'"' -f2 || true)
    
    if [[ -n "$ISO_NAME" ]]; then
        DOWNLOAD_URL="https://release.archboot.com${ISO_NAME}"
    else
        # Fallback to last known working release url
        DOWNLOAD_URL="https://release.archboot.com/aarch64/latest/iso/archboot-2026.06.19-02.07-7.0.12-3-aarch64-ARCH-latest-aarch64.iso"
    fi
    
    echo "Downloading latest Archboot ISO from: $DOWNLOAD_URL"
    curl -L -o "$ISO_FILE" "$DOWNLOAD_URL"
fi

# Configure VM Specifications
VM_MEM="4G"
VM_CPUS="4"

QEMU_CMD=(
    qemu-system-aarch64
    -M virt,highmem=on
    -accel hvf
    -cpu host
    -smp "$VM_CPUS"
    -m "$VM_MEM"
    -bios "$EFI_FIRMWARE"
    -drive file="$DISK_IMAGE",if=virtio,format=qcow2
    -device virtio-gpu-pci
    -display default
    -device virtio-keyboard-pci
    -device virtio-mouse-pci
    -netdev user,id=net0,hostfwd=tcp::2222-:22
    -device virtio-net-pci,netdev=net0
    -serial stdio
)

if [[ "$BOOT_ISO" = true ]]; then
    # Add CD-ROM drive flags
    QEMU_CMD+=(
        -drive file="$ISO_FILE",media=cdrom,if=none,id=cd0
        -device virtio-blk-device,drive=cd0
    )
    
    echo ""
    echo "INSTALLATION GUIDANCE:"
    echo "1. Once the QEMU window opens, select the Archboot interactive installer."
    echo "2. Log in (root / no password)."
    echo "3. Run 'archboot-allinone.sh' to start the menu installation script."
    echo "4. Partition disk /dev/vda:"
    echo "   - Create a GPT partition table."
    echo "   - Boot partition: 512MB, formatted as FAT32 (EFI System Partition)."
    echo "   - Root partition: remaining size, formatted as EXT4."
    echo "5. Configure package installation, mount boot to /boot, and install base packages."
    echo "6. Be sure to enable and start sshd service during installation setup."
    echo "7. Once complete, shutdown the VM and re-run this script choosing Option 1."
    echo ""
fi

echo "Starting QEMU VM..."
echo "${QEMU_CMD[@]}"
echo ""

exec "${QEMU_CMD[@]}"
