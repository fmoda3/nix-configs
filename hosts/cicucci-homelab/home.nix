{
  imports = [
    ../../home
  ];

  home = {
    sessionVariables = {
      NH_OS_FLAKE = ".#nixosConfigurations.cicucci-homelab";
    };
  };

  my-home = {
    includeFonts = true;
    useNeovim = true;
  };
}
