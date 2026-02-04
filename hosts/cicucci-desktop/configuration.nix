{
  imports = [
    ../../darwin
  ];

  my-darwin = {
    enableSudoTouch = true;
    enableRemoteBuilder = true;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
