{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.my-linux;
in
{

  imports = [
    ./openssh
    ./adguardhome
    ./unbound
    ./tailscale
    ./tailscale-autoconnect
    ./vmware
  ];

  options.my-linux = {
    enableNixOptimise = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether we should enable nix auto optimizations
      '';
    };

    tailscale = lib.mkOption {
      description = "tailscale submodile";
      default = { };
      type = types.submodule {
        options = {
          enable = lib.mkOption {
            type = types.bool;
            default = false;
            description = ''
              Whether we should run tailscale
            '';
          };

          authkey = mkOption {
            type = types.str;
            default = null;
            example = "tskey-kveqY12CNTRL-wQHntvWh7JgruYi1iwVgy";
            description = ''
              A one-time use tailscale key
            '';
          };

          advertiseExitNode = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Should tailscale advertise as an exit node
            '';
          };
        };
      };
    };

    adblocker = lib.mkOption {
      description = "adblocker submodule";
      default = { };
      type = types.submodule {
        options = {
          enable = lib.mkOption {
            type = types.bool;
            default = false;
            description = ''
              Whether we should run an adblocker
            '';
          };

          useUnbound = lib.mkOption {
            type = types.bool;
            default = false;
            description = ''
              Should the adblocker run unbound as the backing dns provider
            '';
          };
        };
      };
    };

    vmware = lib.mkOption {
      description = "vmware tools";
      default = { };
      type = types.submodule {
        options = {
          enable = lib.mkOption {
            type = types.bool;
            default = false;
            description = ''
              Enable vmware tools
            '';
          };

          headless = lib.mkOption {
            type = types.bool;
            default = false;
            description = ''
              Enable headless mode
            '';
          };
        };
      };
    };
  };

  config = {
    nix = {
      package = pkgs.nixStable;
      settings = {
        auto-optimise-store = cfg.enableNixOptimise;
        # Add cache for nix-community, used mainly for neovim nightly
        substituters = [ "https://nix-community.cachix.org" ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      gc = optionalAttrs cfg.enableNixOptimise {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      # Enable Flakes
      extraOptions = ''
        experimental-features = nix-command flakes
        ${optionalString cfg.enableNixOptimise ''
          min-free = ${toString (100 * 1024 * 1024)}
          max-free = ${toString (1024 * 1024 * 1024)}
        ''}
      '';
    };

    programs.zsh = {
      enable = true;
      enableCompletion = false;
      promptInit = "";
    };

    users.defaultUserShell = pkgs.zsh;

    system.stateVersion = "22.05";
  };

}
