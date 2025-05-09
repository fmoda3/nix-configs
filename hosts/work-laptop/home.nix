{
  imports = [
    ../../home
  ];

  home = {
    sessionVariables = {
      NH_DARWIN_FLAKE = ".#darwinConfigurations.work-laptop";
    };
  };

  age.secrets.flaggy_token.file = ../../secrets/flaggy_token.age;

  my-home = {
    includeFonts = true;
    useNeovim = true;
    isWork = true;
  };
}
