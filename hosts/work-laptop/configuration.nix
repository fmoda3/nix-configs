{
  imports = [
    ../../darwin
  ];

  my-darwin = {
    isWork = true;
    enableSudoTouch = true;
    enableNixOptimise = true;
  };

  # Work laptop required custom build ids
  ids = {
    uids.nixbld = 450;
    gids.nixbld = 30000;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
