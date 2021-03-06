{ config, pkgs, ...}:
let
  extensions = (with pkgs.vscode-extensions; [
      bbenoist.Nix
    ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
      name = "nord-visual-studio-code";
      publisher = "arcticicestudio";
      version = "0.15.1";
      sha256 = "0lc50jkwxq3vffpwlkqdnkq77c7gbpfn1lk9l0n9qxsyfyhb68qj";
  }];
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
