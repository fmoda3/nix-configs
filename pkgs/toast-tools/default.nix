{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "toast-tools";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/devtools-python-common.git";
    rev = "0738a908d8c03d9ff042ce44027f70cc4c77040a";
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
