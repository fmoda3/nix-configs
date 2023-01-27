{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "toast-tools";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/devtools-python-common.git";
    rev = "46e050e05342d20d0a87e8280744de695241412f";
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
