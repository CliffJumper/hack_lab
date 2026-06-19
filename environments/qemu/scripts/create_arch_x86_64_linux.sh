#!/usr/bin/env bash

# create_arch_x86_64_linux.sh
# Creates and runs an Arch Linux VM on x86_64 Linux.

set -euo pipefail

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ISO_DIR="$QEMU_DIR/images/isos"
IMAGE_DIR="$QEMU_DIR/images/base_images"
CONFIG_DIR="$QEMU_DIR/config"

# Ensure directories exist
mkdir -p "$ISO_DIR" "$IMAGE_DIR" "$CONFIG_DIR"

# Validate Host OS (Linux)
OS="$(uname -s)"
if [[ "$OS" != "Linux" ]]; then
    echo "Warning: This script is intended to run on Linux, but detected: $OS" >&2
    echo "Continuing anyway..." >&2
fi

# Verify QEMU dependencies
if ! command -v qemu-system-x86_64 &>/dev/null || ! command -v qemu-img &>/dev/null; then
    echo "Error: qemu-system-x86_64 and/or qemu-img are not installed." >&2
    echo "Please install QEMU using your system's package manager." >&2
    echo "On Arch Linux: pacman -S qemu-desktop qemu-img" >&2
    echo "On Debian/Ubuntu: apt install qemu-system-x86 qemu-utils" >&2
    exit 1
fi

DISK_IMAGE="$IMAGE_DIR/arch-x86_64.qcow2"
DISK_SIZE="20G"
ISO_FILE="$ISO_DIR/archlinux-x86_64.iso"
PREBUILT_QCOW2_URL="https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2"
OFFICIAL_ISO_URL="https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"

echo "=========================================================="
echo " Arch Linux QEMU Manager (x86_64 / Linux)"
echo "=========================================================="
echo "Choose one of the options below:"
echo "1) Boot from existing disk image (Run VM)"
echo "2) Download and set up official prebuilt basic image (Instant & Recommended)"
echo "3) Download official ISO and perform custom install (Boot from ISO)"
read -r -p "Enter choice [1-3]: " choice

BOOT_ISO=false
DOWNLOAD_PREBUILT=false

case "$choice" in
    2)
        DOWNLOAD_PREBUILT=true
        ;;
    3)
        BOOT_ISO=true
        ;;
    *)
        # Default option 1: run existing disk
        if [[ ! -f "$DISK_IMAGE" ]]; then
            echo "Error: Disk image not found at $DISK_IMAGE." >&2
            echo "Please run this script again and choose Option 2 or 3 to initialize the VM." >&2
            exit 1
        fi
        ;;
esac

# Handle Prebuilt Download
if [[ "$DOWNLOAD_PREBUILT" = true ]]; then
    if [[ -f "$DISK_IMAGE" ]]; then
        read -r -p "An existing disk image already exists at $DISK_IMAGE. Overwrite? [y/N]: " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "Cancelled. Exiting."
            exit 0
        fi
    fi
    echo "Downloading official pre-built Arch Linux basic QCOW2 image..."
    curl -L -o "$DISK_IMAGE" "$PREBUILT_QCOW2_URL"
    echo "Resizing image to $DISK_SIZE..."
    qemu-img resize "$DISK_IMAGE" "$DISK_SIZE"
    echo ""
    echo "Pre-built image ready! Default credentials are:"
    echo "  Username: arch"
    echo "  Password: arch"
    echo "  (Use ssh -p 2222 arch@localhost)"
    echo ""
fi

# Handle Custom ISO Boot and Blank Disk
if [[ "$BOOT_ISO" = true ]]; then
    if [[ ! -f "$DISK_IMAGE" ]]; then
        echo "Creating blank virtual disk image: $DISK_IMAGE ($DISK_SIZE)..."
        qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
    fi
    
    if [[ ! -f "$ISO_FILE" ]]; then
        echo "Downloading official Arch Linux x86_64 ISO from $OFFICIAL_ISO_URL..."
        curl -L -o "$ISO_FILE" "$OFFICIAL_ISO_URL"
    fi
fi

# Configure VM Specifications
VM_MEM="4G"
VM_CPUS="4"

# Set up KVM acceleration if available
ACCEL_FLAGS="-cpu host"
if [[ -e /dev/kvm ]]; then
    ACCEL_FLAGS="-accel kvm -cpu host"
    echo "Using KVM acceleration..."
else
    echo "KVM acceleration not available (/dev/kvm missing). Emulation will be slow!" >&2
fi

QEMU_CMD=(
    qemu-system-x86_64
    $ACCEL_FLAGS
    -smp "$VM_CPUS"
    -m "$VM_MEM"
    -drive file="$DISK_IMAGE",if=virtio,format=qcow2
    -vga virtio
    -display default
    -netdev user,id=net0,hostfwd=tcp::2222-:22
    -device virtio-net-pci,netdev=net0
)

if [[ "$BOOT_ISO" = true ]]; then
    QEMU_CMD+=(
        -cdrom "$ISO_FILE"
        -boot d
    )
    echo ""
    echo "INSTALLATION GUIDANCE:"
    echo "1. Once the VM boots, run 'archinstall' to start the guided installation script."
    echo "2. Follow the prompt to install Arch Linux on the virtio disk (/dev/vda)."
    echo "3. Be sure to configure network and enable/start SSH service during setup."
    echo "4. Once finished, shutdown the VM and restart this script choosing Option 1."
    echo ""
fi

echo "Starting QEMU VM..."
echo "${QEMU_CMD[@]}"
echo ""

exec "${QEMU_CMD[@]}"
