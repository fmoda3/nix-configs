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
    binfmt.emulatedSystems = ["x86_64-linux"];
  };

  imports = [
    ./hardware-configuration.nix
    ../../linux
  ];

  hardware.video.hidpi.enable = true;

  networking = {
    hostName = "cicucci-aarch64-linux-builder";
    useDHCP = false;
    networkmanager = {
      enable = true;
    };
  };

  time.timeZone = "America/New_York";

  security.sudo.wheelNeedsPassword = false;

  i18n.defaultLocale = "en_US.UTF-8";

  # Disable the default module and import our override. We have
  # customizations to make this work on aarch64.
  disabledModules = [ "virtualisation/vmware-guest.nix" ];

  # Interface is this on M1
  networking.interfaces.ens160.useDHCP = true;

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  # This works through our custom module imported above
  virtualisation.vmware.guest.enable = true;
  virtualisation.vmware.guest.headless = true;  
}
