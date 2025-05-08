{
  description = "Example Python Project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, flake-parts }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { pkgs, ... }: {
        packages.default = pkgs.poetry2nix.mkPoetryApplication { projectDir = self; };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            (poetry2nix.mkPoetryEnv { projectDir = self; })
            poetry
          ];
        };
      };
    };
}
