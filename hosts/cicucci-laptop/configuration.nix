{
  imports = [
    ../../darwin
  ];

  my-darwin = {
    enableSudoTouch = true;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
