{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "typish";
  version = "1.9.3";
  format = "wheel";

  src = pkgs.python3Packages.fetchPypi {
    inherit pname version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    sha256 = "15pqwa1gjqszfx79yxymj23lq1219i78zqa40bwxnmmqdrgfxkq3";
  };

  doCheck = false;
}
