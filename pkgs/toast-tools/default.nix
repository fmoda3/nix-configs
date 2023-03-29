{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "toast-tools";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/devtools-python-common.git";
    rev = "2ed33f21d9e8c78d0f8a700fd6fff638d9d1afe3";
    ref = "master";
  };

  doCheck = false;

  propagatedBuildInputs = with pkgs; with python3Packages; [
    boto3
    click
    docker
    psycopg2
    pyyaml
    gitpython
    texttable
    packaging
    pync
    arrow
    requests
  ];

}
