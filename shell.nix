{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    buildInputs = [
        pkgs.rnix-lsp
    ];
}
