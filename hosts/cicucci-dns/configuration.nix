{ config, pkgs, lib, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  imports = [
    ./hardware-configuration.nix
    ../../linux
  ];

  hardware.enableRedistributableFirmware = true;
  networking = {
    hostName = "cicucci-dns";
    networkmanager = {
      enable = true;
    };
  };

  # These are buggy, and work around is to disable them
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services = {
    NetworkManager-wait-online.enable = lib.mkForce false;
    systemd-networkd-wait-online.enable = lib.mkForce false;
  };

  time.timeZone = "America/New_York";

  users.users."root".openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQvuvRu2zwNLsogF6jeoVOC4UUZikF80Bv4ONjGPcDDQTcHHW+b1Re4rozSZ8p76J1Hv3T55YtA7t6ls8mTbBi17CDuHExQlVL0+qvf8QVNj2YPw6eTTqekrWb25ZRiJptGeDZKomjC+KgC2gIpEh01Xzs+lrliY3tNUToBaCAjd41VDtIpBDxRPzxRuBW14qGLaM7zMZuoq4HjaROcImHATXOrib0D7ueGlvW7RRGKhES7i4pJeWvXFBLPwHw4RCKOuL+ZaInB0T3l8TtUsbFWygdFZ5hcJZ+SzwcEKwtdnr3dgADurYY889oFqbj9a1xq1slH8c+S4JkaBZ/lNfzNDXsF1YsGsjtRJ1YIDjtad5bnQnN7j6d4xilad7Hz3Pbw1hy08sq+efQBiuEWJpaO0WJyehv929QRLi9JZuS3jZEhAiOhlU+btmJPPSnfyKVtY4DC7CZ1rEVfZI+/Ff4H4du8GOm5QUqhQ02fHv8SHgq/JwouqbnNvkyt2U5xCk="
  ];

  my-linux = {
    enableNixOptimise = true;
    tailscale = {
      enable = true;
      authkey = ./tailscale_file.txt;
      advertiseExitNode = true;
    };
    adblocker = {
      enable = true;
      useUnbound = true;
    };
    unifi.enable = true;
  };

}
