{
  description = "Example Python Project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = pkgs.poetry2nix.mkPoetryApplication { projectDir = self; };
        devShell = pkgs.mkShell {
          packages = with pkgs; [
            (poetry2nix.mkPoetryEnv { projectDir = self; })
            poetry
          ];
        };
      }
    );
}
