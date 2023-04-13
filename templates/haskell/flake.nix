{
  description = "Example Haskell Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        devShell = pkgs.haskellPackages.shellFor {
          packages = p: [ ];

          buildInputs = with pkgs.haskellPackages; [ cabal-install ghcid ];

          withHoogle = true;
        };
      });
}
