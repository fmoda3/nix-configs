{ config, pkgs, ... }: {
  imports = [
    ../../darwin
  ];

  my-darwin = {
    isWork = true;
    enableSudoTouch = true;
  };
}
