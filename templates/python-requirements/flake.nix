{
  description = "Example Python Project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mach-nix.url = "github:DavHau/mach-nix?ref=3.5.0";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, mach-nix }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          mach-nix-wrapper = import mach-nix { inherit pkgs; };
          requirements = builtins.readFile ./requirements.txt;
          pythonShell = mach-nix-wrapper.mkPythonShell { inherit requirements; };
        in
        {
          devShells.default = pythonShell;
        };
    };
}
