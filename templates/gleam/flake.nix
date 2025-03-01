{
  description = "Example Gleam Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          inputs = with pkgs; [
            gleam
          ];
        in
        {
          devShells.default = pkgs.mkShell {
            packages = inputs;
          };
        };
    };
}
