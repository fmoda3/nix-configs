{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "jsons";
  version = "1.6.1";
  format = "wheel";

  src = pkgs.python3Packages.fetchPypi {
    inherit pname version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    sha256 = "1v835vjfwiwfqqgdi76inlk0b9mqffyk8g5fbfrz165a0dblirsi";
  };

  propagatedBuildInputs = with pkgs.python3Packages; [
    typish
  ];

  pythonImportsCheck = [
    "jsons"
  ];

  meta = with lib; {
    description = "Turn Python objects into dicts or json strings and back";
    homepage = "https://github.com/ramonhagenaars/jsons";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}