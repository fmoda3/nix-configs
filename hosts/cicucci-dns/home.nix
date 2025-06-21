{
  imports = [
    ../../home
  ];

  home = {
    sessionVariables = {
      NH_OS_FLAKE = ".#nixosConfigurations.cicucci-dns";
    };
  };

  age.secrets.personal_github_key.file = ../../secrets/personal_github_key.age;

  my-home = { };
}
