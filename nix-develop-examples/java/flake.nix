{ 
  description = "Example Java Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            jdk11
            gradle
          ];
          shellHook = ''
            export JAVA_HOME=${pkgs.jdk11}
            PATH="${pkgs.jdk11}/bin:$PATH"
          '';
        };
      });
}
