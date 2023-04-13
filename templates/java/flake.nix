{
  description = "Example Java Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
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

        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      {
        devShell = pkgs.mkShell {
          packages = with pkgs; [ jdk gradle maven ];
        };
      }
    );
}
