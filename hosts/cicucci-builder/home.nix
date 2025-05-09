{
  imports = [
    ../../home
  ];

  home = {
    sessionVariables = {
      NH_DARWIN_FLAKE = ".#darwinConfigurations.cicucci-builder";
    };
  };

  my-home = { };
}
