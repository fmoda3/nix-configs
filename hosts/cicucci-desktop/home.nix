{
  imports = [
    ../../home
  ];

  my-home = {
    includeFonts = true;
    useNeovim = true;
    includeGames = true;
    flake = ".#darwinConfigurations.cicucci-desktop";
  };
}
