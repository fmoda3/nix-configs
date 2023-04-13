{
  description = "Example Python Project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "github:DavHau/mach-nix?ref=3.4.0";
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mach-nix-wrapper = import mach-nix { inherit pkgs; };
        requirements = builtins.readFile ./requirements.txt;
        pythonShell = mach-nix-wrapper.mkPythonShell { inherit requirements; };
      in
      { devShell = pythonShell; });
}
