{ config, pkgs, ... }: {
  imports = [
    ../../darwin
  ];

  my-darwin = {
    enableSudoTouch = true;
  };
}
