{
  imports = [
    ../../home
  ];

  home = {
    sessionVariables = {
      NH_DARWIN_FLAKE = ".#darwinConfigurations.cicucci-desktop";
    };
  };

  my-home = {
    includeFonts = true;
    useNeovim = true;
    includeGames = true;
  };
}
