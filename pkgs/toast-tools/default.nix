{ lib
, python3Packages
}:

python3Packages.buildPythonPackage rec {
  pname = "toast-tools";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/devtools-python-common.git";
    rev = "67a2222d96a8c7a9e4cd0994393e9ee5ff7fad52";
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
