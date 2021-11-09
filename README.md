# Installation Instructions

## Install Nix (Linux and macOS)

[Nix Installation Guide](https://nixos.org/manual/nix/stable/installation/installing-binary.html)

The following will install single-user on Linux and multi-user on macos:


      sh <(curl -L https://nixos.org/nix/install)

To install multi-user on Linux:

      sh <(curl -L https://nixos.org/nix/install) --daemon

## Enable Flakes:

Create a file in `~/.config/nix/nix.conf` and add the following:

    experimental-features = nix-command flakes

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
