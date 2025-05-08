{
  description = "Example Java Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { pkgs, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: prev: rec {
              jdk = prev.jdk11;
              gradle = prev.gradle.override {
                java = jdk;
              };
              maven = prev.maven.override {
                inherit jdk;
              };
            })
          ];
          config = { };
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ jdk gradle maven ];
        };
      };
    };
}
