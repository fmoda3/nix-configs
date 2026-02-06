{ config, pkgs, lib, ... }:
let
  cfg = config.installer;

  inherit (cfg.targetSystem.config.system) build;

  # disko
  disko = pkgs.writeShellScriptBin "disko" ''${build.diskoScript}'';
  disko-mount = pkgs.writeShellScriptBin "disko-mount" "${build.mountScript}";
  disko-format = pkgs.writeShellScriptBin "disko-format" "${build.formatScript}";

  system = build.toplevel;

  # installer script
  install-system = pkgs.writeShellScriptBin "install-system" ''
    set -euo pipefail

    echo "Formatting disks..."
    . ${disko-format}/bin/disko-format

    echo "Mounting disks..."
    . ${disko-mount}/bin/disko-mount

    echo "Installing system..."
    nixos-install --system ${system}

    echo "Done!"
  '';
in
{
  options.installer = {
    targetSystem = lib.mkOption {
      type = lib.types.attrs;
      default = null;
      description = ''
        A reference to a built nixosSystem
      '';
    };
  };

  config = {
    # we don't want to generate filesystem entries on this image
    disko.enableConfig = lib.mkDefault false;

    # add disko commands to format and mount disks
    environment.systemPackages = [
      disko
      disko-mount
      disko-format
      install-system
    ];
  };
}
