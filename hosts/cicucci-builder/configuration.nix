{ pkgs, ... }: {
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
    hostName = "cicucci-aarch64-linux-builder";
    useDHCP = false;
    networkmanager = {
      enable = true;
    };
    # Interface is this on M1
    interfaces.ens160.useDHCP = true;
  };

  time.timeZone = "America/New_York";

  security.sudo.wheelNeedsPassword = false;

  users.users."root".openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwu5RO/BMeiQnBtQo0sN+qOBK6v24cQbHfpr0H06NreWOMS3345I7ST5ncDrZlSCRluarpR95Bo1d0QGF1RjBWITUCAVgGX04IqywmlsGkiZVDtJjmOElxIkgFPnOAjXJ977WGVbgRxC5e5Z88Byp4zymWJ0kvF9sdhNL3VoXfYPrO2rFzQGxTcGDKcrmgEkn/8kmq4S+4vrJ0hmukAON63RkTvbC/P4eH23HcHC7sM+pm4hbsL7baxbNRp7kdf++2h4S0FbJ2snuH2ocHE/c4AAv4bOA3nFrmLckP5fsMIMAEP4mluPqyrQjJvDgdCpJfzmv8oZ4Q2TmjS9Civqh/4NI4Ptmse4jOp9SlyM0OEReXS/RBlXeg7t/Yft7Gv47bRwY65TzeRuu8Db5jUCruy36BJgHc74ybxqLak8+XcM83hMdPJtXalYYyAKfwermfM5uGwjuvrfrK9Nh/bVa0DmOk/rZq4veoQyHSf4xttAAg4VPEXjMVA6WfD8+r3aE="
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  # Lots of stuff that uses aarch64 that claims doesn't work, but actually works.
  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };

  virtualisation.vmware.guest.enable = true;
}
