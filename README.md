# Installation

## Install Nix (Linux and macOS) via one of the following installers

### 1.) [Official Installer](https://nixos.org/manual/nix/stable/installation/installing-binary.html)

The following will install single-user on Linux and multi-user on macOS:

```shell
sh <(curl -L https://nixos.org/nix/install)
```

To install multi-user on Linux:

```shell
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Enable Flakes by creating a file in `~/.config/nix/nix.conf` and adding the following:

```shell
experimental-features = nix-command flakes
```

### 2.) [Determinate Systems Installer](https://zero-to-nix.com/concepts/nix-installer)

The following will install Nix on either Linux or macOS:

```shell
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Flakes should already be enabled after install with this method

## Clone Repo
```shell
nix-shell -P git # If you need access to git
git clone git@github.com:fmoda3/nix-configs.git ~/.nix-configs
```    

## Build Flake

Substitute `personal-laptop` for current machine's configuration
### On Darwin:
```shell
cd ~/.nix-configs
nix build ".#darwinConfigurations.personal-laptop.system"
./result/sw/bin/darwin-rebuild switch --flake ".#personal-laptop"
```

### On NixOS:
```shell
cd ~/.nix-configs
nix build ".#nixosConfigurations.personal-laptop.system"
sudo ./result/sw/bin/nixos-rebuild switch --flake ".#personal-laptop"
```

# Updating

## Updating flake.lock

If the flake.lock needs to be updated:

```shell
nix flake update
```

## Rebuilding and Switching

To rebuild after making changes:

### On Darwin

```shell
darwin-rebuild build --flake ".#personal-laptop"
darwin-rebuild switch --flake ".#personal-laptop"
```

### On NixOS:
```shell
sudo nixos-rebuild build --flake ".#personal-laptop"
sudo nixos-rebuild switch --flake ".#personal-laptop"
```

# Creating new configurations

1. Create a new folder in the `hosts` folder with the name of the configuration.
2. Inside that folder, create a `configuration.nix` with a NixOS or Darwin config, and a `home.nix` with a home manager config.
3. Add a new configuration to either the `nixosConfigurations` or `darwinConfigurations` block of the `flake.nix`, specifying the system type, host (the name of the folder from step 1), and user (to install the home manager config to).

# Using Images

## Building a disk image

Substitute `bootable-x86_64-iso` for the image configuration you want to build

```shell
nix build ".#images.bootable-x86_64-iso"
```

## Specific Images

### cicucci-builder-iso

This image builds a bootable iso, that boots into a standard NixOS installation, with a script that installs the `cicucci-builder` nixos system configuration to the disk.

1. Build the iso via
   ```shell
   nix build ".#images.cicucci-builder-iso"
   ```
2. Boot the iso on new machine (either a VM, or burn to usb drive and boot from it on a physical machine)
3. After the terminal prompt appears, run
   ```shell
   sudo install-system
   ```
   This will partition and mount the drive using the [Disko](https://github.com/nix-community/disko) config in the `cicucci-builder` configuration, and then install the `cicucci-builder` configuration itself.
4. Once complete, `sudo reboot` to boot into the freshly installed system.
5. To make updates after install, clone this repo, and follow the updating steps above.

### cicucci-builder-vm

This image builds the `cicucci-builder` configuration directly into a vmware image.  After building, the image can be booted from vmware.

### cicucci-dns-sd

This image builds a bootable sd image, that boots directly into a system with the `cicucci-dns` configuration.  This configuration is intended to be used on a Raspberry Pi 3.

1. Build sd via
   ```shell
   nix build ".#images.cicucci-dns-sd"
   ```
2. Burn sd image to an sd card using a sd burning utility of your choice.
3. Boot Raspberry Pi directly from sd.  The `cicucci-dns` system will already be installed.

Note that the sd image doesn't have a Disko config and therefore doesn't do any partition or mounting.  This is because the base NixOS sd image automatically resizes the base partition to fill the available size of the sd card on first boot.

### bootable-x86_64-iso, bootable-aarch64-iso, and bootable-aarch64-sd

These images are general purpose installers, that don't target a specific configuration.  They do add a few pieces of my config on top of the base installer that are useful to have, like my zsh configs.

# Remote Deployment

I use [deploy-rs](https://github.com/serokell/deploy-rs) to deploy the `cicucci-dns` configuration remotely to my Raspberry Pi.  I do this because running `nixos-rebuild` on the Pi itself is very slow.  I deploy from a macOS machine, that is also running a NixOS vm, setup with the `cicucci-builder` configuration.

## Setup

1. Ensure a `aarch64-linux` machine is available to build.  I run an `aarch64-linux` NixOS vm with the `cicucci-builder` configuration inside vmware on a `aarch64-darwin` machine.
2. If the `aarch64-linux` machine is a remote builder (i.e., not your current machine), ensure that your current machine's `root` user can ssh into the `root` user of the remote builder, via ssh key authentication (add your computer's public rsa key into the `authorized_keys` file of the remote builder)
3. Ensure that your current machine's `root` user can ssh into the `root` user of the Raspberry Pi, also via ssh key authentication explained above.

## Deploy

1. Simply run `deploy`

# Using Templates

The templates are for initializing project specific nix flakes into their directories.

Substitute `elixir` with the template you want in the commands below.

## Generate a template into an existing project
```shell
nix flake init --template "github:fmoda3/nix-configs#elixir"
```

## Generate a new project with a template
```shell
nix flake new --template "github:fmoda3/nix-configs#elixir" ${NEW_PROJECT_DIRECTORY}
```

# Formatting

This flake's formatting is set to use `nixpkgs-fmt`.  Formatting works via
```shell
nix fmt
```

# Pre Commit Hooks

This flake uses the [pre-commit-hook](https://github.com/cachix/pre-commit-hooks.nix) project run git hooks on commit.  Currently, it verifies that the flake is properly linted and formatted before commit.

# Devshell

This flake uses the [devshell](https://github.com/numtide/devshell) project to easily setup a dev environment when in this project's directory.  It adds a few packages to the environment, as well as aliases to format, lint, and build various images.

To enter the devshell without `direnv`, run

```shell
nix develop
```

If you use `direnv`, it should become available anytime you are in the directory after running

```shell
direnv allow
```