{
  description = "Example Python Project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    mach-nix.url = "github:DavHau/mach-nix?ref=3.4.0";
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, mach-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mach-nix-wrapper = import mach-nix { inherit pkgs; };
        requirements = builtins.readFile ./requirements.txt;
        pythonShell = mach-nix-wrapper.mkPythonShell { inherit requirements; };
      in { devShell = pythonShell; });
}
