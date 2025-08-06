{
  imports = [
    ../../home
  ];

  my-home = {
    flake = ".#darwinConfigurations.cicucci-builder";
  };
}
