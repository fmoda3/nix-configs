# Installation Instructions

## Install Nix (Linux and macOS) via one of the following installers:

### 1.) [Official Installer](https://nixos.org/manual/nix/stable/installation/installing-binary.html)

The following will install single-user on Linux and multi-user on macOS:


      sh <(curl -L https://nixos.org/nix/install)

To install multi-user on Linux:

      sh <(curl -L https://nixos.org/nix/install) --daemon

Enable Flakes by creating a file in `~/.config/nix/nix.conf` and adding the following:

    experimental-features = nix-command flakes

### 2.) [Determinate Systems Installer](https://zero-to-nix.com/concepts/nix-installer)

The following will install Nix on either Linux or macOS:

    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

Flakes should already be enabled after install with this method

## Clone Repo:

    git clone git@github.com:fmoda3/nix-configs.git ~/.nix-configs

## Build Flake

Substitute "personal-laptop" for current machine's configuration

    cd ~/.nix-configs
    nix build ".#darwinConfigurations.personal-laptop.system"
    ./result/sw/bin/darwin-rebuild switch --flake .#personal-laptop

## Rebuilding

To rebuild after making changes:

    darwin-rebuild build --flake .#personal-laptop
    darwin-rebuild switch --flake .#personal-laptop

## Updating flake.lock

If the flake.lock needs to be updated:

    nix flake update
