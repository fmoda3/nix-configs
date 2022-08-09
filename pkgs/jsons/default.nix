{ lib, pkgs, fetchFromGitHub, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "jsons";
  version = "1.6.3";

  src = fetchFromGitHub {
    owner = "ramonhagenaars";
    repo = "jsons";
    rev = "0sdwc57f3lwzhbcapjdbay9f8rn65rlspxa67a2i5apcgg403qpc";
    sha256 = "0sdwc57f3lwzhbcapjdbay9f8rn65rlspxa67a2i5apcgg403qpc";
  };

  propagatedBuildInputs = with pkgs.python3Packages; [
    typish
  ];

  checkInputs = with pkgs.python3Packages; [
    attrs
    tzdata
  ] ++ lib.optionals pkgs.python3Packages.isPy36 [
    dataclasses
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
