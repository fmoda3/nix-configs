{ lib
, python3Packages
, autossh
}:

python3Packages.buildPythonPackage rec {
  pname = "braid";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/braid.git";
    rev = "7cf499bd3c866aa7b2fbd5dc9cd7ccc34c0c73f0";
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
  ];

  postPatch = ''
    substituteInPlace setup.py \
      --replace "version=Version().version," "version='0.1.0',"
  '';

}
