{ lib
, python3Packages
, autossh
}:

python3Packages.buildPythonPackage rec {
  pname = "braid";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/braid.git";
    rev = "add018dcff41e2a7ed8d4c753e3749d8b099677e";
    ref = "main";
  };

  doCheck = false;

  propagatedBuildInputs = with python3Packages; [
    autossh
    click
    docker
    psycopg2
    prettytable
    pyyaml
    toast-tools
    psutil
    inquirerpy
    dateutil
    parameterized
    boto3
    environs
    gitpython
    cachetools
  ];

  postPatch = ''
    substituteInPlace setup.py \
      --replace "version=Version().version," "version='0.1.0',"
  '';

}
