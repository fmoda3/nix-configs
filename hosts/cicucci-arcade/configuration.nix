{ config, pkgs, lib, ... }: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "0";
      };
      efi.canTouchEfiVariables = true;
    };
    binfmt.emulatedSystems = [ "x86_64-linux" ];
  };

  imports = [
    ./hardware-configuration.nix
    ../../linux
  ];

  networking = {
    hostName = "cicucci-arcade";
    useDHCP = false;
    networkmanager = {
      enable = true;
    };
    # Interface is this on M1
    interfaces.ens160.useDHCP = true;
  };

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };

  virtualisation.vmware.guest.enable = true;

  # This works through our custom module imported above
  my-linux = {
    arcade.enable = true;
  };
}
