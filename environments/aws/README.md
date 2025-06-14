# AWS Environment

This directory contains all the code and configuration files for the AWS-based lab environment.

## Directory Structure

- `terraform/` - Contains all Terraform configuration files
  - `main.tf` - Main Terraform configuration
  - `variables.tf` - Input variables
  - `outputs.tf` - Output values
  - `modules/` - Reusable Terraform modules
- `scripts/` - Helper scripts for AWS environment management
  - `setup.sh` - Initial environment setup
  - `cleanup.sh` - Environment cleanup
  - `monitor.sh` - Resource monitoring
- `config/` - Configuration files
  - `aws_config.json` - AWS-specific configurations
  - `network_config.json` - Network setup configurations

## Usage

1. Navigate to the terraform directory
2. Initialize Terraform: `terraform init`
3. Apply configuration: `terraform apply`
4. Use scripts in the `scripts` directory for additional management tasks 