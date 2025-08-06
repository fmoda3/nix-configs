{
  imports = [
    ../../home
  ];

  my-home = {
    includeFonts = true;
    useNeovim = true;
    flake = ".#nixosConfigurations.cicucci-homelab";
  };
}
