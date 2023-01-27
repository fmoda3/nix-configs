{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "braid";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/braid.git";
    rev = "519b9d194fbf8081e9fb923f0cd47b051aa9f5fa";
    ref = "main";
  };

  doCheck = false;

  propagatedBuildInputs = with pkgs; with python3Packages; [
    autossh
    click
    docker
    psycopg2
    prettytable
    pyyaml
    toast-tools
    psutil
  ];

}
