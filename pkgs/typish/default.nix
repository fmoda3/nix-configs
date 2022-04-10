{ lib
, buildPythonPackage
, fetchPypi
}:

buildPythonPackage rec {
  pname = "typish";
  version = "1.9.3";
  format = "wheel";

  src = fetchPypi {
    inherit pname version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    sha256 = "15pqwa1gjqszfx79yxymj23lq1219i78zqa40bwxnmmqdrgfxkq3";
  };

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
