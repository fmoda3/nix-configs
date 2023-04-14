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

  time.timeZone = "America/New_York";

  users.users."root".openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCUyEgGUe113CxXA5dDq8etNboIPqpp6BQ4q80k0ClZFMgUnHZAvMqpV93XJgvVbVCuJl5fKIOruIwrUE2sMKmg31Xm4OGSX00gbxOAIUTd/k4iwAVAPLeOaSC3KM3vK9TtKFl6ZEkSnTlS4ymClp2ZqNzc/4yIN/PoT/QRPacN9CvWAA1euGnd8i1JuXMTyJB/ibsVzztsAdwnOWdCio7NyxqOpeRLPWlKYny/QwJeaxwCEPyHmzc2zluHiIRd3L/6vUriHajSOuUtd/dH8e/a5AnyFBDJMHy/vKj/ODLsdoO1g9b3kC6dTFh4Rga/fhvod9utR4Jj5DxxRaJf9pLNRoZap99nUfu3seplGitu+fdCKXFVItdgXluZIRSgZiLCOW9LJUxGJ3Sf4igbyE8gCIefAILxpXEDqSev+4b3OfMyXeYAwTookuKU4kU5IxpD82lS+LkKeyCBaSYIAtUlZnXLds4TkeO8sasVzGqbFA342/OHAXjsRb8AFyGjP2c="
  ];

  my-linux = {
    enableNixOptimise = true;
    tailscale = {
      enable = true;
      authkey = "tskey-kveqY12CNTRL-wQHntvWh7JgruYi1iwVgy";
      advertiseExitNode = true;
    };
    adblocker = {
      enable = true;
      useUnbound = true;
    };
  };

}
