{ config, pkgs, lib, ... }:
with lib;
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
    enableSudoTouch = lib.mkEnableOption "sudo touch id";
  };

  config = {
    nix = {
      package = pkgs.nixStable;
      # Add cache for nix-community, used mainly for neovim nightly
      settings = {
        substituters = [ "https://nix-community.cachix.org" ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      # Enable Flakes
      extraOptions = "experimental-features = nix-command flakes";
      # An aarch64-linux vm running nixos, so I can build my raspberry pi config
      # on it and deploy remotely.  Building on the rpi3 directly is super slow.
      buildMachines = [
        {
          hostName = "192.168.123.132";
          sshUser = "root";
          systems = [ "aarch64-linux" "x86_64-linux" ];
          supportedFeatures = [ "big-parallel" ];
        }
      ];
      # Required for the above build machines to be used.
      distributedBuilds = true;
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
