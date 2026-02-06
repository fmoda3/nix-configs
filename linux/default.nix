{ config, pkgs, lib, ... }:
let
  cfg = config.my-linux;
in
{

  imports = [
    ./adguardhome
    ./openssh
    ./tailscale
    ./unbound
  ];

  options.my-linux = {
    enableNixOptimise = lib.mkEnableOption "nix auto optimizations";

    tailscale = lib.mkOption {
      description = "tailscale submodule";
      default = { };
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "tailscale";
          advertiseExitNode = lib.mkEnableOption "advertise exit node";

          authkey = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "/run/secrets/tailscale_key";
            description = ''
              A one-time use tailscale key
            '';
          };
        };
      };
    };

    adblocker = lib.mkOption {
      description = "adblocker submodule";
      default = { };
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "adblocker";
          # Should the adblocker run unbound as the backing dns provider
          useUnbound = lib.mkEnableOption "unbound";
        };
      };
    };
  };

  config = {
    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        auto-optimise-store = cfg.enableNixOptimise;
        # Add cache for nix-community, used mainly for neovim nightly
        substituters = [ "https://nix-community.cachix.org" ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      gc = lib.optionalAttrs cfg.enableNixOptimise {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      # Enable Flakes
      extraOptions = ''
        experimental-features = nix-command flakes
        ${lib.optionalString cfg.enableNixOptimise ''
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
  };

}
