{ lib
, python3Packages
}:

python3Packages.buildPythonPackage rec {
  pname = "toast-tools";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/devtools-python-common.git";
    rev = "a5fcac406eeef56119bba0ae5a04f14fc382443b";
    ref = "master";
  };

  doCheck = false;

  propagatedBuildInputs = with python3Packages; [
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
