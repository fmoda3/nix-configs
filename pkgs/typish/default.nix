{ lib, pkgs, fetchFromGitHub, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "typish";
  version = "1.9.3";

  src = fetchFromGitHub {
    owner = "ramonhagenaars";
    repo = "typish";
    rev = "7875850f55e2df8a9e2426e2d484ab618e347c7f";
    sha256 = "0mc5hw92f15mwd92rb2q9isc4wi7xq76449w7ph5bskcspas0wrf";
  };

  checkInputs = with pkgs.python3Packages; [
    numpy
    pytestCheckHook
  ];

  disabledTestPaths = [
    # Requires old version of nptyping which circular depends on typish
    "tests/functions/test_instance_of.py"
  ];

  pythonImportsCheck = [
    "typish"
  ];

  meta = with lib; {
    description = "Library for checking types of objects";
    homepage = "https://github.com/ramonhagenaars/typish";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
