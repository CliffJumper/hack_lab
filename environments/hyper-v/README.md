# Hyper-V Environment

This directory contains all the scripts and configuration files for the Hyper-V-based lab environment.

## Directory Structure

- `scripts/` - Helper scripts for Hyper-V environment management
  - `create_vm.ps1` - VM creation script
  - `network_setup.ps1` - Network configuration
  - `cleanup.ps1` - Environment cleanup
  - `monitor.ps1` - Resource monitoring
- `config/` - Configuration files
  - `hyperv_config.json` - Hyper-V-specific configurations
  - `network_config.json` - Network setup configurations
  - `vm_templates/` - VM template configurations
- `images/` - VM disk images and ISOs
  - `base_images/` - Base OS images
  - `custom_images/` - Customized VM images
  - `isos/` - Installation media

## Usage

1. Place required ISO files in the `images/isos` directory
2. Configure VM settings in `config/hyperv_config.json`
3. Run setup scripts from the `scripts` directory using PowerShell
4. Use monitoring scripts to check resource usage 