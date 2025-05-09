{
  imports = [
    ../../home
  ];

  home = {
    sessionVariables = {
      NH_OS_FLAKE = ".#nixosConfigurations.cicucci-dns";
    };
  };

  my-home = { };
}
