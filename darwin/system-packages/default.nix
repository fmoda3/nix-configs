{ pkgs, ... }:
let
  extensions = (with pkgs.vscode-extensions; [
    bbenoist.nix
  ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "nord-visual-studio-code";
      publisher = "arcticicestudio";
      version = "0.19.0";
      sha256 = "05bmzrmkw9syv2wxqlfddc3phjads6ql2grknws85fcqzqbfl1kb";
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
  environment.systemPackages = [
    pkgs.kitty
    vscode-with-extensions
  ];
}
