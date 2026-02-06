{ config, pkgs, lib, ... }:
let
  cfg = config.my-darwin;
in
{

  imports = [
    ./homebrew
    ./system-defaults
    # ./system-packages
    # Uncomment to bring Yabai back
    # ./wm
  ];

  options.my-darwin = {
    isWork = lib.mkEnableOption "work profile";
    isServer = lib.mkEnableOption "server profile";
    enableSudoTouch = lib.mkEnableOption "sudo touch id";
    enableRemoteBuilder = lib.mkEnableOption "remote builder for distributed builds";
    enableNixOptimise = lib.mkEnableOption "nix auto optimizations";
  };

  config = {
    nix = {
      package = pkgs.nixVersions.stable;
      # Add cache for nix-community, used mainly for neovim nightly
      settings = {
        substituters = [ "https://nix-community.cachix.org" ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      optimise = lib.optionalAttrs cfg.enableNixOptimise {
        automatic = true;
        interval = { Weekday = 0; Hour = 3; Minute = 0; };
      };
      gc = lib.optionalAttrs cfg.enableNixOptimise {
        automatic = true;
        interval = { Weekday = 0; Hour = 2; Minute = 0; };
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
      linux-builder = {
        # Use nix-darwin's managed Linux builder VM.
        enable = cfg.enableRemoteBuilder;
        systems = [ "aarch64-linux" "x86_64-linux" ];
      };
    };

    # Create /etc/zshrc that loads the nix-darwin environment.
    programs.zsh = {
      enable = true;
      # This fixes a bug between nix darwin and home-manager over completion conflicts
      # Completion is enabled in home-manager config
      enableCompletion = false;
      promptInit = "";
    };

    security.pam.services.sudo_local = {
      touchIdAuth = cfg.enableSudoTouch;
      reattach = cfg.enableSudoTouch;
    };

  };

}
