{ config, pkgs, ... }: {
  imports = [
    ../../darwin
  ];

  my-darwin = { };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
