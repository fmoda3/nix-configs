{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.my-darwin;
in {

  imports = [
    ./system-defaults
    # ./system-packages
    ./fonts
    # yabai doesn't yet work with Monterey
    # ./wm/themes/nord.nix
    ./homebrew
  ];

  options.my-darwin = {
    isWork = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this is a work profile
      '';
    };
  };

  config = {
    # Make sure nix always runs in multi-user mode on Mac
    services.nix-daemon.enable = true;

    # Enable Flakes
    nix = {
      package = pkgs.nixFlakes;
      extraOptions = "experimental-features = nix-command flakes";
    };

    # Create /etc/zshrc that loads the nix-darwin environment.
    programs.zsh = {
      enable = true;
      # This fixes a bug between nix darwin and home-manager over completion conflicts
      # Completion is enabled in home-manager config
      enableCompletion = false;
      promptInit = "";
    };

    # Overlays
    # nixpkgs.overlays = [
    #   (import ./overlays/yabai.nix)
    # ];

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 4;
  };

  
}
