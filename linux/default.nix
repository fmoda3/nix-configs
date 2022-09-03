{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.my-linux;
in {

  imports = [
    ./openssh
    ./adguardhome
    ./unbound
    ./tailscale
    ./tailscale-autoconnect
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
  };

  config = {
    # Enable Flakes
    nix = {
      package = pkgs.nixFlakes;
      settings.auto-optimise-store = cfg.enableNixOptimise;
      gc = optionalAttrs cfg.enableNixOptimise {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
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
