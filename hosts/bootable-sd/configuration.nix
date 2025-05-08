{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  imports = [
    ../../linux
  ];

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };

  my-linux = { };

}
