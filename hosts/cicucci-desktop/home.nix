{
  imports = [
    ../../home
  ];

  home = {
    sessionVariables = {
      NH_DARWIN_FLAKE = ".#darwinConfigurations.cicucci-desktop";
    };
  };

  age.secrets.personal_github_key.file = ../../secrets/personal_github_key.age;

  my-home = {
    includeFonts = true;
    useNeovim = true;
    includeGames = true;
  };
}
