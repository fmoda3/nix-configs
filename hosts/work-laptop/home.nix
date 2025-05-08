{
  imports = [
    ../../home
  ];

  age.secrets.flaggy_token.file = ../../secrets/flaggy_token.age;

  my-home = {
    includeFonts = true;
    useNeovim = true;
    isWork = true;
  };
}
