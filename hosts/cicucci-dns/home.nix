{
  imports = [
    ../../home
  ];

  my-home = {
    flake = ".#nixosConfigurations.cicucci-dns";
  };
}
