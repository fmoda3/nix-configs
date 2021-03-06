# Installation Instructions

## Install Nix (Linux and macOS)

[Nix Installation Guide](https://nixos.org/manual/nix/stable/#ch-installing-binary)

For Linux:

* Single User:

      sh <(curl -L https://nixos.org/nix/install)

* Multi User:

      sh <(curl -L https://nixos.org/nix/install) --daemon

For macOS:

Note: Multi User is highly recommended, as [nix-darwin defaults to multi-user](https://github.com/LnL7/nix-darwin/issues/287), and [may remove single user support in the future](https://github.com/NixOS/nix/pull/4289).

* Single User:

      sh <(curl -L https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume

* Multi User:

      sh <(curl -L https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume --daemon

## Clone Repo:

If you need git (may need to uninstall this later as it can conflict with Home Manager's version):

    nix-env -iA nixpkgs.git

Clone:

    git clone git@github.com:fmoda3/nix-configs.git ~/.nix-configs

## Install Nix Darwin (macOS only)

[Nix Darwin Installation Guide](https://github.com/LnL7/nix-darwin#install)

Run Installer:

    nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
    ./result/bin/darwin-installer

Answers to prompts:

    Would you like edit the default configuration.nix before starting? [y/n] n
    Would you like to manage <darwin> with nix-channel? [y/n] y
    Would you like to load darwin configuration in /etc/bashrc? [y/n] y
    Would you like to create /run? [y/n] y

Link Config:

    rm ~/.nixpkgs/darwin-configuration.nix
    ln -s ~/.nix-configs/darwin/darwin-configuration.nix ~/.nixpkgs/darwin-configuration.nix

Switch to config:

    darwin-rebuild switch

## Install Home Manager (Linux and macOS)

[Home Manager Installation Guide](https://github.com/nix-community/home-manager#installation)

Add Home Manager Channel:

    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update

Install Home Manager:

    nix-shell '<home-manager>' -A install

Link Config:

    rm ~/.config/nixpkgs/home.nix
    ln -s ~/.nix-configs/home-manager/home.nix ~/.config/nixpkgs/home.nix

Switch to config:

    home-manager switch

## Known Issues

* If you installed Nix in Single User mode, and then installed Nix Darwin with nix-daemon enabled (multi-user, and the default), [you may run into permissions issues](https://github.com/LnL7/nix-darwin/issues/188) when executing nix.  These permissions can be fixed by:

      chown -R root:nixbld /nix
      chmod 1777 /nix/var/nix/profiles/per-user
      chown -R $USER:staff /nix/var/nix/profiles/per-user/$USER
      mkdir -m 1777 -p /nix/var/nix/gcroots/per-user
      chown -R $USER:staff /nix/var/nix/gcroots/per-user/$USER

* This warning is a [known issue](https://github.com/LnL7/nix-darwin/issues/295):

    > warning: Nix search path entry '/nix/var/nix/profiles/per-user/root/channels' does not exist, ignoring
