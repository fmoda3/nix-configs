{ config, pkgs, ...}:
let
  extensions = (with pkgs.vscode-extensions; [
      bbenoist.Nix
    ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "nord-visual-studio-code";
        publisher = "arcticicestudio";
        version = "0.15.1";
        sha256 = "0lc50jkwxq3vffpwlkqdnkq77c7gbpfn1lk9l0n9qxsyfyhb68qj";
      }
      {
        name = "vscode-theme-onedark";
        publisher = "akamud";
        version = "2.2.3";
        sha256 = "1m6f6p7x8vshhb03ml7sra3v01a7i2p3064mvza800af7cyj3w5m";
      }
    ];
  vscode-with-extensions = pkgs.vscode-with-extensions.override {
    vscodeExtensions = extensions;
  };
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.kitty
    vscode-with-extensions
  ];
}
