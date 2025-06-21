{
  imports = [
    ../../home
  ];

  home = {
    sessionVariables = {
      NH_DARWIN_FLAKE = ".#darwinConfigurations.work-laptop";
    };
  };

  my-home = {
    includeFonts = true;
    useNeovim = true;
    isWork = true;
  };
}
