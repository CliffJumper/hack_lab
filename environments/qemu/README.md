# QEMU Environment

This directory contains all the scripts and configuration files for the QEMU-based lab environment.

## Directory Structure

- `scripts/` - Helper scripts for QEMU environment management
  - `create_vm.sh` - VM creation script
  - `network_setup.sh` - Network configuration
  - `cleanup.sh` - Environment cleanup
  - `monitor.sh` - Resource monitoring
- `config/` - Configuration files
  - `qemu_config.json` - QEMU-specific configurations
  - `network_config.json` - Network setup configurations
  - `vm_templates/` - VM template configurations
- `images/` - VM disk images and ISOs
  - `base_images/` - Base OS images
  - `custom_images/` - Customized VM images
  - `isos/` - Installation media

## Usage

1. Place required ISO files in the `images/isos` directory
2. Configure VM settings in `config/qemu_config.json`
3. Run setup scripts from the `scripts` directory
4. Use monitoring scripts to check resource usage 