{ pkgs, ... }: {
  boot.kernelPackages = pkgs.linuxPackages;

  imports = [
    ../../linux
  ];

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };

  my-linux = { };
}
