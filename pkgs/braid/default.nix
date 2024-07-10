{ lib
, python3Packages
, autossh
}:

python3Packages.buildPythonPackage rec {
  pname = "braid";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/braid.git";
    rev = "2c9b1f28ef8060fd54a65a6c6da7ea392382ded0";
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
    pylint
    texttable
  ];

  postPatch = ''
    substituteInPlace setup.py \
      --replace "version=Version().version," "version='0.1.0',"
  '';

}
