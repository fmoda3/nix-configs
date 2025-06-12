# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive Nix configuration repository managing multiple machines (macOS and Linux) using Nix Flakes. It includes system configurations, Home Manager user configurations, custom packages, and deployment automation.

## Common Commands

### System Management
```bash
# Build and switch configurations
darwin-rebuild switch --flake ".#cicucci-desktop"  # macOS
sudo nixos-rebuild switch --flake ".#cicucci-dns"  # Linux

# Update flake inputs
nix flake update

# Enter development environment
nix develop
```

### Code Quality
```bash
format     # Format Nix files with nixpkgs-fmt
lint       # Run statix linter
nix fmt    # Alternative formatting
```

### Image Building (devshell commands)
```bash
create-aarch64-iso    # ARM64 installation ISO
create-x86_64-iso     # x86_64 installation ISO
create-dns-sd         # Raspberry Pi SD card image
```

### Secrets Management
```bash
age-edit <file>       # Edit encrypted secrets
age-rekey            # Rekey all secrets
```

### Deployment
```bash
deploy               # Deploy to remote systems
```

## Architecture

### Core Structure
- **flake.nix**: Main configuration defining all system outputs
- **hosts/**: Machine-specific configurations organized by hostname
- **home/**: Home Manager modules for user-level tools and applications
- **darwin/**: macOS-specific system configurations
- **linux/**: nixos-specific system configurations
- **pkgs/**: Custom package definitions and overlays
- **secrets/**: Age-encrypted secrets management

### System Types
- **darwinConfigurations**: macOS systems (cicucci-desktop, cicucci-laptop, work-laptop)
- **nixosConfigurations**: Linux systems (cicucci-dns, cicucci-homelab, cicucci-builder)
- **images**: Bootable installation media

### Package Management
- Custom packages defined in `pkgs/` are available as `pkgs.packageName`
- Uses overlays to integrate custom packages with nixpkgs
- Supports multiple nixpkgs channels (stable, unstable, master)

### Multi-Architecture Support
- Supports ARM64 and x86_64 architectures
- Uses remote builders for cross-compilation
- Specialized configurations for different hardware types

## Key Features

### Configuration Modularity
- Shared modules in `home/` and `darwin/` directories
- Host-specific configurations compose shared modules
- Conditional configurations based on machine type (work vs personal)

### Secrets Management
- Uses agenix for encrypted secrets
- Secrets are per-machine and can be shared across machines
- Automatic rekeying when keys change

### Remote Deployment
- Uses deploy-rs for remote system management
- Configurations for multiple remote systems
- Automated deployment pipelines

### Development Environment
- Direnv integration for automatic environment loading
- Pre-commit hooks for code quality
- Development shells with necessary tools (nixd, statix, agenix)
