{ lib
, python3Packages
}:

python3Packages.buildPythonPackage rec {
  pname = "toast-tools";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/devtools-python-common.git";
    rev = "3b70424860eef69caf50bbeda91ec26c5b9885df";
    ref = "master";
  };

  doCheck = false;

  propagatedBuildInputs = with python3Packages; [
    boto3
    click
    docker
    psycopg2
    pylint
    pyyaml
    gitpython
    texttable
    packaging
    psutil
    pync
    arrow
    requests
  ];

}
