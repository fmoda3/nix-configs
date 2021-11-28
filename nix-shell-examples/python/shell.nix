{ pkgs ? import <nixpkgs> {} }:
let
  python-with-my-packages = pkgs.python3.withPackages (p: with p; [
    requests
    # other python packages you want
  ]);
in
pkgs.mkShell {
  buildInputs = [
    python-with-my-packages
    pkgs.pyright
  ];
  shellHook = ''
    PYTHONPATH=${python-with-my-packages}/${python-with-my-packages.sitePackages}
  '';
}
