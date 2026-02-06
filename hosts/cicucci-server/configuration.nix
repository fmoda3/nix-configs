{
  imports = [
    ../../darwin
  ];

  my-darwin = {
    isServer = true;
    enableNixOptimise = true;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
