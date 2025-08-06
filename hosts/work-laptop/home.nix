{
  imports = [
    ../../home
  ];

  my-home = {
    includeFonts = true;
    useNeovim = true;
    isWork = true;
    flake = ".#darwinConfigurations.work-laptop";
  };
}
