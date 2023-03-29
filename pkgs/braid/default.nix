{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "braid";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/braid.git";
    rev = "63b807c04a35a305a224a917df97c19bcf8078aa";
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
    dateutil
    boto3
  ];

  postPatch = ''
    substituteInPlace setup.py \
      --replace "version=Version().version," "version='0.1.0',"
  '';

}
